# terraform-azurerm-avm-containerregistry

Module to deploy Container Registries in Azure.

As a starting point, the azurerm_container_registry resource has been implemented, noting this supports all attributes such as georeplication and zone redundancy.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>

## Migrating customer-managed encryption to direct inputs

The module now takes the key URI and encryption identity's client ID directly. It no longer reads either resource through internal data sources.

| Previous `customer_managed_key` field | Replacement |
| --- | --- |
| `key_vault_resource_id` + `key_name` + optional `key_version` | `key_vault_key_uri` |
| `user_assigned_identity.resource_id` | `user_assigned_identity.client_id` |

Before, a caller creating a new key in an existing vault could supply the already-known vault ARM ID and a literal key name. The module's key data source had no dependency on the new key resource and could try to read it before it existed.

Before (versionless key):

```hcl
customer_managed_key = {
  key_vault_resource_id = azurerm_key_vault.shared.id
  key_name             = "registry-key"
  user_assigned_identity = {
    resource_id = azurerm_user_assigned_identity.acr.id
  }
}
```

After:

```hcl
customer_managed_key = {
  key_vault_key_uri = azurerm_key_vault_key.acr.versionless_id
  user_assigned_identity = {
    client_id = azurerm_user_assigned_identity.acr.client_id
  }
}
managed_identities = {
  user_assigned_resource_ids = [azurerm_user_assigned_identity.acr.id]
}
```

These are inputs supplied by the caller to the registry module. The references to the caller's key and identity resources establish dependency edges: Terraform orders the registry after them even when a referenced value is already known during planning. Do not replace a new key's resource reference with a literal URI merely because the strings match.

`managed_identities.user_assigned_resource_ids` still takes **ARM resource IDs** and attaches identities to the registry. `customer_managed_key.user_assigned_identity.client_id` selects the encryption identity from those attached identities. The module retains a check that at least one user-assigned identity is attached, but cannot prove that a client ID belongs to one of the supplied ARM IDs without a lookup. The caller must supply a matching identity with permission to use the key.

For keys and identities that already exist, caller-owned data sources or outputs from their owning configuration are appropriate. For example, pass an existing key data source's `versionless_id` and an identity data source's `client_id`, while continuing to attach the identity's `id`.

Preserve the existing rotation choice during upgrade:

- If `key_version` was omitted or null, use the same key's versionless URI, such as `https://example.vault.azure.net/keys/registry-key`.
- If `key_version` was set, supply the same URI including that exact version. Use a key resource's `id` only when it refers to the intended version.

The module passes the URI host through unchanged. A mocked test accepting a Managed HSM or sovereign-cloud host is not evidence that encryption was deployed successfully with that service.

Review the upgrade plan before applying. This interface change keeps resource addresses, but that alone does not guarantee that every existing configuration upgrades without changes or replacements.

## AzAPI provider and ignored body paths

The root and AzAPI child modules require `Azure/azapi ~> 2.12` (`>= 2.12, < 3.0`). All consumers must resolve a compatible provider, even if they do not use cache rules or encryption.

- An existing constraint such as `~> 2.4` **overlaps** `~> 2.12`; it does not need changing.
- If the lock file selects an older provider, run `terraform init -upgrade` and review the lock-file changes.
- If a caller explicitly constrains AzAPI to a range excluding 2.12, update that constraint before initialization can succeed.

The new `ignore_body_changes` input uses ARM-derived resource keys. For example, the root module passes `ignore_body_changes.containerregistry_registries_credential_sets` unchanged to each credential-set child. That child's own `containerregistry_registries_credential_sets` list identifies paths in its resource body:

```hcl
ignore_body_changes = {
  containerregistry_registries_credential_sets = {
    containerregistry_registries_credential_sets = ["properties.authCredentials"]
  }
}
```

Use non-empty, body-relative dot paths, not individual list indices. Ignored configuration is not sent to Azure until the path is removed. The provider stores these settings privately, and changes take effect only after apply. Adding a path can still show its old diff in that plan; removing one can leave the diff suppressed until the following plan.

Populated lists require Terraform 1.11 or later. Empty lists are converted to `null`.

**Known compatibility blocker:** On Terraform versions earlier than 1.11, validation can fail with `WriteOnly Attribute Not Allowed`, even when every list is empty. During validation, the empty-to-null expression can be unknown rather than null, and the provider framework rejects unknown write-only values on those Terraform versions. This is tracked in [Azure/terraform-provider-azapi#1240](https://github.com/Azure/terraform-provider-azapi/issues/1240) and [hashicorp/terraform-plugin-framework#1328](https://github.com/hashicorp/terraform-plugin-framework/issues/1328).

## Migrating from the `resource` output

The full `resource` output has been removed because the provider resource object contains sensitive attributes and its schema can change between provider versions. Use the discrete outputs instead:

| Previous reference | Replacement |
| --- | --- |
| `module.container_registry.resource.id` | `module.container_registry.resource_id` |
| `module.container_registry.resource.name` | `module.container_registry.name` |
| `module.container_registry.resource.login_server` | `module.container_registry.login_server` |
| `module.container_registry.resource.admin_username` | `module.container_registry.admin_username` |
| `module.container_registry.resource.admin_password` | `module.container_registry.admin_password` |
| `module.container_registry.resource.data_endpoint_host_names` | `module.container_registry.data_endpoint_host_names` |
| `module.container_registry.resource.identity[0].principal_id` | `module.container_registry.system_assigned_mi_principal_id` |
| `module.container_registry.resource.identity[0].tenant_id` | `module.container_registry.system_assigned_mi_tenant_id` |

The admin username and password outputs are sensitive and are only populated when the registry admin account is enabled. Azure recommends using an individual identity, managed identity, service principal, or repository-scoped token instead of sharing the admin account. For more information, see [Authenticate with an Azure container registry](https://learn.microsoft.com/azure/container-registry/container-registry-authentication).

## Resource locks and private endpoints

Private endpoints inherit the Container Registry lock by default. Set `private_endpoints_inherit_lock` to `false` to disable inheritance. A lock configured directly on a `private_endpoints` entry takes precedence over an inherited lock.

`CanNotDelete` prevents deletion while allowing updates. `ReadOnly` also prevents updates and can block changes to private endpoint properties, application security group associations, or private DNS zone groups. With externally managed DNS zone groups, apply the lock only after the external controller or Azure Policy has finished configuring the private endpoint.

Terraform removes module-managed locks before destroying their protected resources. Azure lock removal is eventually consistent, so a destroy can fail temporarily with `ScopeLocked`; retry the operation after the lock removal has propagated.

## Migrating to `AbacRepositoryPermissions`

Both authorization modes remain supported. When switching an existing registry to `AbacRepositoryPermissions`, stage the change to avoid interrupting access:

1. Add ABAC-compatible repository role assignments for identities using `AcrPull`, `AcrPush`, or `AcrDelete`.
2. Set `role_assignment_mode = "AbacRepositoryPermissions"` and apply.
3. Validate repository access.
4. Optionally remove the obsolete legacy role assignments.
