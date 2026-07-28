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
