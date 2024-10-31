terraform {
  required_version = "~> 1.6"
  required_providers {
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

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "australiasoutheast"
  name     = module.naming.resource_group.name_unique
}

# This is the module call
module "containerregistry" {
  source = "../../"
  # source             = "Azure/avm-containerregistry-registry/azurerm"
  name                = module.naming.container_registry.name_unique
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
