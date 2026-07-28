# terraform-azurerm-avm-containerregistry

Module to deploy Container Registries in Azure.

As a starting point, the azurerm_container_registry resource has been implemented, noting this supports all attributes such as georeplication and zone redundancy.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>

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

## Migrating to `AbacRepositoryPermissions`

The `role_assignment_mode` variable selects the authorization model for the registry. It defaults to `LegacyRegistryPermissions`, which keeps the registry-wide roles (`AcrPull`, `AcrPush`, `AcrDelete`, and similar) and preserves existing behaviour. Setting it to `AbacRepositoryPermissions` enables attribute-based access control (ABAC) so that access can be scoped per repository, which is the model Microsoft recommends for new deployments.

Both modes are fully supported and will remain available; there is no requirement to move off `LegacyRegistryPermissions`.

When switching an **existing** registry to `AbacRepositoryPermissions`, stage the change so that access is never interrupted:

1. **Add ABAC-compatible role assignments first.** While the registry is still in `LegacyRegistryPermissions`, grant the ABAC repository roles (for example `Container Registry Repository Reader`, `Container Registry Repository Writer`, `Container Registry Repository Contributor`) to the identities that currently rely on `AcrPull`/`AcrPush`/`AcrDelete`. You can do this through the `role_assignments` variable or outside the module.
2. **Switch the mode.** Set `role_assignment_mode = "AbacRepositoryPermissions"` and apply.
3. **Validate access.** Confirm that every consumer (pipelines, workloads, and users) can still pull, push, and manage content as expected under the new repository-scoped assignments.
4. **Remove obsolete assignments only after validation.** Once access is confirmed, you may optionally clean up the now-redundant registry-wide `AcrPull`/`AcrPush`/`AcrDelete` assignments.

Do not remove the legacy registry-wide assignments before completing steps 1–3, otherwise consumers may lose access during the transition.
