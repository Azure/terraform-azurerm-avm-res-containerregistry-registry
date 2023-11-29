terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = "australiasoutheast"
}

# This is the module call
module "containerregistry" {
  source = "../../"
  # source             = "Azure/avm-containerregistry-registry/azurerm"
  name                = module.naming.container_registry.name_unique
  enable_telemetry    = var.enable_telemetry
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  # australiasoutheast doesn't support zone redundancy for ACR (https://learn.microsoft.com/en-us/azure/container-registry/zone-redundancy#regional-support)
  zone_redundancy_enabled = false

  georeplications = [
    {
      location = "australiaeast"
      # zone redundancy is enabled by default, and is supported in australia east
      tags = {
        environment = "prod"
        department  = "engineering"
      }
    },
    {
      location                = "australiacentral"
      zone_redundancy_enabled = false
      tags = {
        environment = "pre-prod"
        department  = "engineering"
      }
    }
  ]
}
