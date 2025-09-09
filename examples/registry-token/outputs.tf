output "scope_maps" {
  description = "values of the scope maps"
  sensitive   = true
  value       = module.containerregistry.scope_maps
}
