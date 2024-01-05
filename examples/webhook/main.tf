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
  location = "australiaeast"
}

locals {
  webhooks = {
    exampleWebhook = {
      actions = ["push", "delete"]
      custom_headers = {
        "Content-Type" = "application/json"
      }
      name        = "webhook1"
      scope       = "repo:myexampletag1"
      service_uri = "https://example.com/webhook1"
      status      = "enabled"
      tags = {
        environment = "test"
        team        = "devops"
      }
    },
    anotherExampleWebhook = {
      actions = ["push", "chart_push"]
      custom_headers = {
        "X-Custom-Header" = "some-custom-header-value"
      }
      name        = "webhook2"
      scope       = "repo:*"
      service_uri = "https://notify.example.com/webhook2"
      status      = "enabled"
      tags = {
        environment = "staging"
        team        = "devops"
      }
    }
  }
}

module "containerregistry" {
  source = "../../"
  # source             = "Azure/avm-containerregistry-registry/azurerm"
  name                = module.naming.container_registry.name_unique
  resource_group_name = azurerm_resource_group.this.name
  webhooks            = local.webhooks
}
