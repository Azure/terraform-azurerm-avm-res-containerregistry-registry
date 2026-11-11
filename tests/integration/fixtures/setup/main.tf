terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

variable "location" {
  type        = string
  description = "The Azure region for the test resource group."
  nullable    = false
}

data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location  = var.location
  name      = "rg-acr-upgrade-${random_string.suffix.result}"
  parent_id = data.azapi_client_config.current.subscription_resource_id
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
}

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
