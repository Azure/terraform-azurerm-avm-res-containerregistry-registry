data "azapi_resource" "registry" {
  resource_id = var.resource_id
  type        = "Microsoft.ContainerRegistry/registries@2025-11-01"
  response_export_values = {
    creation_date = "properties.creationDate"
  }
}
