output "id" {
  description = "The ID of the Container Registry Scope Map."
  value       = azurerm_container_registry_scope_map.this.id
}

output "registry_token_passwords" {
  description = "The registry token password object."
  value       = azurerm_container_registry_token_password.this
}

output "registry_tokens" {
  description = "The registry token object."
  value       = azurerm_container_registry_token.this
}

output "resource_id" {
  description = "The resource ID of the Container Registry Scope Map."
  value       = azurerm_container_registry_scope_map.this.id
}
