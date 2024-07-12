terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
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

  name                = module.naming.container_registry.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  zone_redundancy_enabled = false # australiasoutheast does not support zone redundancy for ACR

  georeplications = {
    replication1 = {
      location                  = "australiaeast"
      regional_endpoint_enabled = true
      zone_redundancy_enabled   = true
      tags = {
        environment = "prod"
        department  = "engineering"
      }
    }
    replication2 = {
      location                  = "australiacentral"
      regional_endpoint_enabled = true
      zone_redundancy_enabled   = false
      tags = {
        environment = "pre-prod"
        department  = "engineering"
      }
    }
  }
}
