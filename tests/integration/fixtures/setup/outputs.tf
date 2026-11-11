output "location" {
  description = "The Azure region of the test resource group."
  value       = azapi_resource.resource_group.location
}

output "resource_group_id" {
  description = "The resource ID of the test resource group."
  value       = azapi_resource.resource_group.id
}

output "resource_group_name" {
  description = "The name of the test resource group."
  value       = azapi_resource.resource_group.name
}

output "suffix" {
  description = "A random lowercase alphanumeric suffix for globally unique names."
  value       = random_string.suffix.result
}
