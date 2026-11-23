output "creation_date" {
  description = "The time Azure created the registry. It changes only when the registry is deleted and created again."
  value       = data.azapi_resource.registry.output.creation_date
}
