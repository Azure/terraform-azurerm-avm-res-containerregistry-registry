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
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

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

# Create Key Vault using AVM module to store Docker Hub credentials
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.11.1"

  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku_name            = "standard"

  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = {
    # Current user needs to be able to create secrets
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  # IMPORTANT: Replace these values with your actual Docker Hub credentials
  # You can also use environment variables or other secure methods
  secrets = {
    dockerhub_username = {
      name = "dockerhub-username"
      # REPLACE WITH YOUR DOCKER HUB USERNAME
      value = "your-dockerhub-username"
    }
    dockerhub_password = {
      name = "dockerhub-password"
      # REPLACE WITH YOUR DOCKER HUB PASSWORD OR ACCESS TOKEN
      # It's recommended to use a Docker Hub Access Token instead of your password
      value = "your-dockerhub-password-or-token"
    }
  }
}

# This is the Container Registry module call
module "containerregistry" {
  source = "../../"

  location = azurerm_resource_group.this.location
  # source             = "Azure/avm-res-containerregistry-registry/azurerm"
  name                = module.naming.container_registry.name_unique
  resource_group_name = azurerm_resource_group.this.name

  # Managed identity is required for the credential set to access Key Vault
  managed_identities = {
    system_assigned = true
  }

  # Cache rules for public registries
  cache_rules = {
    # MCR cache (no credentials needed)
    mcr_dotnet = {
      name              = "mcr-dotnet-cache"
      source_repository = "mcr.microsoft.com/dotnet/aspnet"
      target_repository = "cached/dotnet/aspnet"
    }

    # Docker Hub cache (with credentials from Key Vault)
    dockerhub_nginx = {
      name              = "dockerhub-nginx-cache"
      source_repository = "library/nginx"
      target_repository = "cached/nginx"

      credential_set = {
        name               = "dockerhub-credentials"
        login_server       = "docker.io"
        username_secret_id = module.key_vault.resource_secrets["dockerhub_username"].versionless_id
        password_secret_id = module.key_vault.resource_secrets["dockerhub_password"].versionless_id
      }
    }
  }

  sku = "Premium" # Premium SKU is required for cache rules

  depends_on = [module.key_vault]
}

# Grant the credential set's managed identity access to Key Vault secrets using AVM
module "credential_set_role_assignment" {
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.4.0"

  for_each = {
    for k, v in module.containerregistry.cache_rules : k => v
    if v.credential_set != null
  }

  principal_id               = each.value.credential_set.identity[0].principal_id
  role_definition_id_or_name = "Key Vault Secrets User"
  scope_resource_id          = module.key_vault.resource_id
  description                = "Allow credential set ${each.key} to read secrets from Key Vault"
}
