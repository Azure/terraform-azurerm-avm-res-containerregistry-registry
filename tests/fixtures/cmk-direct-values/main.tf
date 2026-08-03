terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    modtm = {
      source = "Azure/modtm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "terraform_data" "key_version" {}

resource "terraform_data" "identity_client_id" {}

module "test" {
  source = "../../.."

  location            = "eastus"
  name                = "acrtest"
  resource_group_name = "rg-test"
  sku                 = "Premium"
  customer_managed_key_direct_values = {
    identity_client_id = terraform_data.identity_client_id.id
    key_vault_key_id   = "https://kv-test.vault.azure.net/keys/cmk-test/${terraform_data.key_version.id}"
  }
  customer_managed_key = {
    key_name              = "cmk-test"
    key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
    user_assigned_identity = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"
    }
  }
  enable_telemetry = false
  managed_identities = {
    user_assigned_resource_ids = toset(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"])
  }
}
