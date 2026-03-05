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

resource "random_string" "suffix" {
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

# This is the module call
module "containerregistry" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.container_registry.name_unique
  resource_group_name = azurerm_resource_group.this.name
  agent_pools = {
    simple = {
      name           = "ap${random_string.suffix.result}"
      instance_count = 1
      tier           = "S1"
    }
  }
  sku = "Premium"
  tasks = {
    build_image = {
      name            = "build${random_string.suffix.result}"
      agent_pool_name = "ap${random_string.suffix.result}"
      platform = {
        os = "Linux"
      }
      encoded_step = {
        task_content = <<-TASK
          version: v1.1.0
          steps:
            - build: >-
                -t $Registry/sample/hello:$ID
                -t $Registry/sample/hello:latest
                https://github.com/Azure-Samples/acr-build-helloworld-node.git#main
            - push:
              - $Registry/sample/hello:$ID
              - $Registry/sample/hello:latest
        TASK
      }
      schedule_run_now = {
        enabled = true
      }
    }

    run_built_periodic = {
      name               = "periodic${random_string.suffix.result}"
      agent_pool_name    = "ap${random_string.suffix.result}"
      timeout_in_seconds = 900
      platform = {
        os = "Linux"
      }
      timer_triggers = {
        every_30_minutes = {
          name     = "every-30-minutes"
          schedule = "*/30 * * * *"
        }
      }
      encoded_step = {
        task_content = <<-TASK
          version: v1.1.0
          steps:
            - cmd: $Registry/sample/hello:latest
        TASK
      }
    }
  }
}
