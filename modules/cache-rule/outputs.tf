output "credential_set" {
  description = "The Container Registry Credential Set resource, if created by this module."
  value       = try(azurerm_container_registry_credential_set.this[0], null)
}

output "id" {
  description = "The ID of the Container Registry Cache Rule."
  value       = azurerm_container_registry_cache_rule.this.id
}

output "resource_id" {
  description = "The resource ID of the Container Registry Cache Rule."
  value       = azurerm_container_registry_cache_rule.this.id
}
