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
  location = "australiaeast"
  name     = module.naming.resource_group.name_unique
}

# This is the module call
module "containerregistry" {
  source = "../../"
  # source             = "Azure/avm-containerregistry-registry/azurerm"
  name                = module.naming.container_registry.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  # Create scope maps for different access levels
  scope_maps = {
    readonly = {
      name = "readonly-scope"
      actions = [
        "repositories/*/content/read",
        "repositories/*/metadata/read"
      ]
      description = "Read-only access to all repositories"
      registry_tokens = {
        readonly_token = {
          name    = "readonly-token"
          enabled = true
          passwords = {
            password1 = {
              expiry = "2025-12-31T00:00:00Z"
            }
          }
        }
      }
    },
    devops = {
      name = "devops-scope"
      actions = [
        "repositories/*/content/read",
        "repositories/*/content/write",
        "repositories/*/content/delete",
        "repositories/*/metadata/read",
        "repositories/*/metadata/write"
      ]
      description = "Full access for DevOps teams"
      registry_tokens = {
        devops_token1 = {
          name    = "devops-token1"
          enabled = true
          passwords = {
            password1 = {
              expiry = "2025-12-31T00:00:00Z"
            }
            password2 = {
              expiry = "2026-12-31T00:00:00Z"
            }
          }
        }
        devops_token2 = {
          name    = "devops-token2"
          enabled = true
        }
      }
    },
    cicd = {
      name = "cicd-scope"
      actions = [
        "repositories/myapp/content/read",
        "repositories/myapp/content/write"
      ]
      description = "CI/CD pipeline access for specific repositories"
    }
  }
}
