output "name" {
  description = "The name of the Container Registry cache rule."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The resource ID of the Container Registry cache rule."
  value       = azapi_resource.this.id
}
