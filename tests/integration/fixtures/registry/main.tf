terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

variable "resource_id" {
  type        = string
  description = "The resource ID of the container registry to read."
  nullable    = false
}

data "azapi_resource" "registry" {
  resource_id = var.resource_id
  type        = "Microsoft.ContainerRegistry/registries@2025-11-01"
  response_export_values = {
    creation_date = "properties.creationDate"
  }
}

output "creation_date" {
  description = "The time Azure created the registry. It changes only when the registry is deleted and created again."
  value       = data.azapi_resource.registry.output.creation_date
}
