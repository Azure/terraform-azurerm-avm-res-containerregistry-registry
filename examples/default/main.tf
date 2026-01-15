terraform {
  required_version = "~> 1.6"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4, < 5.0.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  base_properties = {
    sku = {
      name = "PerGB2018"
    }
    retentionInDays = 30
    features = {
      searchVersion = "2"
    }
  }
}


# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
}

resource "azapi_resource" "workspace" {
  location  = "australiaeast"
  name      = module.naming.application_insights.name_unique
  parent_id = azurerm_resource_group.this.id
  type      = "Microsoft.OperationalInsights/workspaces@2025-02-01"
  body = {
    properties = local.base_properties
  }
  response_export_values = ["id", "name", "properties.customerId"]

  lifecycle {
    ignore_changes = [body.properties.features.searchVersion]
  }
}


# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "australiaeast"
  name     = module.naming.resource_group.name_unique
}

# This is the module call
module "containerregistry" {
  source = "../../"

  location = azurerm_resource_group.this.location
  # source             = "Azure/avm-containerregistry-registry/azurerm"
  name                = module.naming.container_registry.name_unique
  resource_group_name = azurerm_resource_group.this.name
  diagnostic_settings = {
    acr = {
      name                           = "acr-log-analytics"
      workspace_resource_id          = azapi_resource.workspace.id
      log_groups                     = ["allLogs"]
      metric_categories              = ["AllMetrics"]
      log_analytics_destination_type = null
    }
  }
}
