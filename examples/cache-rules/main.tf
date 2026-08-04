terraform {
  required_version = "~> 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4, < 5.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9, < 1.0"
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

data "azurerm_client_config" "this" {}

# Key Vault (RBAC mode) that stores the upstream Docker Hub credentials the
# credential set will reference.
resource "azurerm_key_vault" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.this.tenant_id
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# Allow the deployer to write the demo secrets while the Key Vault is in RBAC mode.
resource "azurerm_role_assignment" "kv_secrets_officer" {
  principal_id         = data.azurerm_client_config.this.object_id
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
}

# Give the data-plane role assignment time to propagate before writing secrets.
resource "time_sleep" "wait_for_kv_rbac" {
  create_duration = "60s"

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "docker_username" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "docker-username"
  value        = "exampleuser" # Replace with a real Docker Hub username in production.

  depends_on = [time_sleep.wait_for_kv_rbac]
}

resource "azurerm_key_vault_secret" "docker_password" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "docker-password"
  value        = "example-access-token" # Replace with a real Docker Hub token in production.

  depends_on = [time_sleep.wait_for_kv_rbac]
}

# This is the module call
module "containerregistry" {
  source = "../../"

  location = azurerm_resource_group.this.location
  # source             = "Azure/avm-res-containerregistry-registry/azurerm"
  name                = module.naming.container_registry.name_unique
  resource_group_name = azurerm_resource_group.this.name
  cache_rules = {
    # Authenticated pull from Docker Hub via a credential set (Docker Hub is
    # rate-limited, so credentials are required). The source repository must be
    # the fully-qualified upstream path.
    dockerhub_nginx = {
      name              = "dockerhub-nginx"
      source_repository = "docker.io/library/nginx"
      target_repository = "nginx"
      credential_set = {
        name         = "dockerhub-credentials"
        login_server = "docker.io"
        auth_credentials = [
          {
            username_secret_identifier = azurerm_key_vault_secret.docker_username.versionless_id
            password_secret_identifier = azurerm_key_vault_secret.docker_password.versionless_id
          }
        ]
      }
    }
    # Unauthenticated pull from Microsoft Container Registry (public, no
    # credential set required).
    mcr_hello_world = {
      name              = "mcr-hello-world"
      source_repository = "mcr.microsoft.com/mcr/hello-world"
      target_repository = "hello-world"
    }
  }
  sku = "Premium" # Premium SKU is required for cache rules.
}

# The credential set's system-assigned identity must be able to read the Key Vault
# secrets. Granting this access is the caller's responsibility; the module exposes
# the discrete `principal_id` so we can create the role assignment without a
# plan-time computed `for_each` (a direct reference to a single map entry).
resource "azurerm_role_assignment" "credential_set_kv_secrets_user" {
  principal_id         = module.containerregistry.credential_sets["dockerhub_nginx"].principal_id
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
}
