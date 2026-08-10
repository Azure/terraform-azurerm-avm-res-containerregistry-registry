output "name" {
  description = "The name of the Container Registry credential set."
  value       = azapi_resource.this.name
}

output "principal_id" {
  description = "The principal ID of the credential set's system-assigned managed identity. Grant this identity read access to the Key Vault secrets referenced by `auth_credentials`."
  value       = azapi_resource.this.identity[0].principal_id
}

output "resource_id" {
  description = "The resource ID of the Container Registry credential set."
  value       = azapi_resource.this.id
}

output "tenant_id" {
  description = "The tenant ID of the credential set's system-assigned managed identity."
  value       = azapi_resource.this.identity[0].tenant_id
}
