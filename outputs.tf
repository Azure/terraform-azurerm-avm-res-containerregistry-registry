output "admin_password" {
  description = "The password associated with the Container Registry admin account."
  sensitive   = true
  value       = azurerm_container_registry.this.admin_password
}

output "admin_username" {
  description = "The username associated with the Container Registry admin account."
  sensitive   = true
  value       = azurerm_container_registry.this.admin_username
}

output "cache_rules" {
  description = <<DESCRIPTION
A map of the Container Registry cache rules created by the module. The map key matches the key supplied to `var.cache_rules`. Each value exposes discrete attributes:

- `name` - The name of the cache rule.
- `resource_id` - The resource ID of the cache rule.
DESCRIPTION
  value = {
    for key, cache_rule in module.cache_rule : key => {
      name        = cache_rule.name
      resource_id = cache_rule.resource_id
    }
  }
}

output "credential_sets" {
  description = <<DESCRIPTION
A map of the Container Registry credential sets created by the module. The map key matches the key supplied to `var.credential_sets`. Each value exposes discrete attributes:

- `name` - The name of the credential set.
- `resource_id` - The resource ID of the credential set.
- `principal_id` - The principal ID of the credential set's system-assigned managed identity. Grant this identity read access to the referenced Key Vault secrets.
- `tenant_id` - The tenant ID of the credential set's system-assigned managed identity.
DESCRIPTION
  value = {
    for key, credential_set in module.credential_set : key => {
      name         = credential_set.name
      resource_id  = credential_set.resource_id
      principal_id = credential_set.principal_id
      tenant_id    = credential_set.tenant_id
    }
  }
}

output "data_endpoint_host_names" {
  description = "The host names of the dedicated data endpoints for the Container Registry."
  value       = azurerm_container_registry.this.data_endpoint_host_names
}

output "login_server" {
  description = "The URL used to log in to the Container Registry."
  value       = azurerm_container_registry.this.login_server
}

output "name" {
  description = "The name of the parent resource."
  value       = azurerm_container_registry.this.name
}

output "private_endpoints" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

# Minimum required outputs
# https://azure.github.io/Azure-Verified-Modules/specs/shared/#id-rmfr7---category-outputs---minimum-required-outputs
output "resource_id" {
  description = "The resource id for the parent resource."
  value       = azurerm_container_registry.this.id
}

output "scope_maps" {
  description = <<DESCRIPTION
A map of scope maps. The map key is the supplied input to var.scope_maps. The map value is the entire scope map module.
The scope map module contains the following outputs:
- `id` - The ID of the Container Registry Scope Map.
- `registry_tokens` - The registry token object.
  - `id` - The ID of the Container Registry token.
  - `registry_token_passwords` - The registry token password object.
    - `id` - The ID of the Container Registry token password.
    - `password1` - The first password object of the token.
    - `password2` - The second password object of the token.
DESCRIPTION
  sensitive   = true
  value       = module.scope_maps
}

output "system_assigned_mi_principal_id" {
  description = "The system assigned managed identity principal ID of the parent resource."
  value       = try(azurerm_container_registry.this.identity[0].principal_id, null)
}

output "system_assigned_mi_tenant_id" {
  description = "The system assigned managed identity tenant ID of the parent resource."
  value       = try(azurerm_container_registry.this.identity[0].tenant_id, null)
}
