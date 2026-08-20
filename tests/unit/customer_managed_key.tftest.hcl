mock_provider "azapi" {}
mock_provider "azurerm" {
  mock_resource "azurerm_container_registry" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/acrtest"
      name = "acrtest"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry    = false
  location            = "eastus"
  name                = "acrtest"
  resource_group_name = "rg-test"
  sku                 = "Premium"
}

run "versionless_key_uri_is_passed_through_unchanged" {
  command   = apply
  state_key = "cmk-versionless"

  variables {
    customer_managed_key = {
      key_vault_key_uri = "https://kv-test.vault.azure.net/keys/cmk"
      user_assigned_identity = {
        client_id = "11111111-1111-1111-1111-111111111111"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"]
    }
  }

  assert {
    condition     = azurerm_container_registry.this.encryption[0].key_vault_key_id == "https://kv-test.vault.azure.net/keys/cmk"
    error_message = "The key URI should reach the registry exactly as supplied, with no module-side construction."
  }

  assert {
    condition     = azurerm_container_registry.this.encryption[0].identity_client_id == "11111111-1111-1111-1111-111111111111"
    error_message = "The registry should be given the identity client ID supplied by the caller."
  }
}

run "versioned_key_uri_is_accepted" {
  command   = apply
  state_key = "cmk-versioned"

  variables {
    customer_managed_key = {
      key_vault_key_uri = "https://kv-test.vault.azure.net/keys/cmk/abcdef0123456789abcdef0123456789"
      user_assigned_identity = {
        client_id = "11111111-1111-1111-1111-111111111111"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"]
    }
  }

  assert {
    condition     = azurerm_container_registry.this.encryption[0].key_vault_key_id == "https://kv-test.vault.azure.net/keys/cmk/abcdef0123456789abcdef0123456789"
    error_message = "A versioned key URI should be passed through unchanged."
  }
}

run "managed_hsm_key_uri_is_accepted" {
  command   = apply
  state_key = "cmk-managed-hsm"

  variables {
    customer_managed_key = {
      key_vault_key_uri = "https://hsm-test.managedhsm.azure.net/keys/cmk"
      user_assigned_identity = {
        client_id = "11111111-1111-1111-1111-111111111111"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"]
    }
  }

  assert {
    condition     = azurerm_container_registry.this.encryption[0].key_vault_key_id == "https://hsm-test.managedhsm.azure.net/keys/cmk"
    error_message = "The caller owns the host, so a Managed HSM key URI should be accepted unchanged."
  }
}

run "no_customer_managed_key_creates_no_encryption_block" {
  command   = apply
  state_key = "cmk-absent"

  assert {
    condition     = length(azurerm_container_registry.this.encryption) == 0
    error_message = "No encryption block should be configured when customer_managed_key is null."
  }
}

run "invalid_key_uri_is_rejected" {
  command   = plan
  state_key = "cmk-invalid-uri"

  variables {
    customer_managed_key = {
      key_vault_key_uri = "https://kv-test.vault.azure.net/secrets/cmk"
      user_assigned_identity = {
        client_id = "11111111-1111-1111-1111-111111111111"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"]
    }
  }

  expect_failures = [var.customer_managed_key]
}

run "non_guid_client_id_is_rejected" {
  command   = plan
  state_key = "cmk-invalid-client-id"

  variables {
    customer_managed_key = {
      key_vault_key_uri = "https://kv-test.vault.azure.net/keys/cmk"
      user_assigned_identity = {
        client_id = "not-a-guid"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"]
    }
  }

  expect_failures = [var.customer_managed_key]
}

run "missing_identity_is_rejected" {
  command   = plan
  state_key = "cmk-missing-identity"

  variables {
    customer_managed_key = {
      key_vault_key_uri = "https://kv-test.vault.azure.net/keys/cmk"
    }
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"]
    }
  }

  expect_failures = [azurerm_container_registry.this]
}

run "unassigned_identity_is_rejected" {
  command   = plan
  state_key = "cmk-unassigned-identity"

  variables {
    customer_managed_key = {
      key_vault_key_uri = "https://kv-test.vault.azure.net/keys/cmk"
      user_assigned_identity = {
        client_id = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  expect_failures = [azurerm_container_registry.this]
}

run "non_premium_sku_is_rejected" {
  command   = plan
  state_key = "cmk-non-premium"

  variables {
    sku = "Standard"
    customer_managed_key = {
      key_vault_key_uri = "https://kv-test.vault.azure.net/keys/cmk"
      user_assigned_identity = {
        client_id = "11111111-1111-1111-1111-111111111111"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"]
    }
  }

  expect_failures = [azurerm_container_registry.this]
}
