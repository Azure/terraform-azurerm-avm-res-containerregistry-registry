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
