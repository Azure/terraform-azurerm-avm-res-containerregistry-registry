output "name" {
  description = "The name of the parent resource."
  value       = azurerm_container_registry.this.name
}

output "private_endpoints" {
  description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "scope_maps" {
  description = <<DESCRIPTION
A map of scope map keys to scope map values. Each scope map value is the entire azurerm_container_registry_scope_map resource.

The scope map value contains the following attributes:
- id: The Container Registry Scope Map ID
- name: The name of the Container Registry Scope Map
- resource_group_name: The name of the resource group in which the Container Registry Scope Map is created
- container_registry_name: The name of the Container Registry associated with the Scope Map
- actions: The list of actions assigned to the Scope Map
- description: The description of the Container Registry Scope Map
DESCRIPTION
  value       = module.scope_maps
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_container_registry.this
}

# Minimum required outputs
# https://azure.github.io/Azure-Verified-Modules/specs/shared/#id-rmfr7---category-outputs---minimum-required-outputs
output "resource_id" {
  description = "The resource id for the parent resource."
  value       = azurerm_container_registry.this.id
}

output "system_assigned_mi_principal_id" {
  description = "The system assigned managed identity principal ID of the parent resource."
  value       = try(azurerm_container_registry.this.identity[0].principal_id, null)
}
