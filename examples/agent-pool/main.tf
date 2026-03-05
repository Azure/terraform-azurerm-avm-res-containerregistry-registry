terraform {
  required_version = "~> 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 5.0.0"
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

resource "random_string" "agent_pool_suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "australiaeast"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.100.0.0/16"]
}

resource "azurerm_subnet" "this" {
  address_prefixes     = ["10.100.1.0/24"]
  name                 = module.naming.subnet.name_unique
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

# This is the module call
module "containerregistry" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.container_registry.name_unique
  resource_group_name = azurerm_resource_group.this.name
  agent_pools = {
    primary = {
      name           = "ap${random_string.agent_pool_suffix.result}"
      instance_count = 1
      tier           = "S1"
    }
    isolated = {
      name                      = "ai${random_string.agent_pool_suffix.result}"
      instance_count            = 1
      tier                      = "S2"
      virtual_network_subnet_id = azurerm_subnet.this.id
    }
  }
  sku = "Premium"
}
