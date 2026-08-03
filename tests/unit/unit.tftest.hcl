mock_provider "azapi" {}
mock_provider "azurerm" {
  mock_resource "azurerm_container_registry" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/acrtest"
      name = "acrtest"
    }
  }

  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateEndpoints/pe-acrtest"
      name = "pe-acrtest"
    }
  }

  mock_data "azurerm_key_vault_key" {
    defaults = {
      versionless_id = "https://kv-test.vault.azure.net/keys/cmk-test"
    }
  }

  mock_data "azurerm_user_assigned_identity" {
    defaults = {
      client_id = "22222222-2222-2222-2222-222222222222"
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
}

run "explicit_private_endpoint_lock" {
  command   = apply
  state_key = "explicit-private-endpoint-lock"

  variables {
    private_endpoints = {
      primary = {
        lock = {
          kind = "CanNotDelete"
          name = "lock-explicit"
        }
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
      }
    }
  }

  assert {
    condition     = length(azurerm_management_lock.private_endpoint) == 1
    error_message = "An explicitly configured private endpoint lock should be created."
  }

  assert {
    condition     = azurerm_management_lock.private_endpoint["primary"].lock_level == "CanNotDelete"
    error_message = "The private endpoint lock should use the explicitly configured lock level."
  }

  assert {
    condition     = azurerm_management_lock.private_endpoint["primary"].name == "lock-explicit"
    error_message = "The private endpoint lock should use the explicitly configured name."
  }

  assert {
    condition     = azurerm_management_lock.private_endpoint["primary"].scope == azurerm_private_endpoint.this["primary"].id
    error_message = "The lock should target the private endpoint with a module-managed DNS zone group."
  }
}

run "inherited_private_endpoint_lock_with_unmanaged_dns" {
  command   = apply
  state_key = "inherited-private-endpoint-lock-with-unmanaged-dns"

  variables {
    lock = {
      kind = "ReadOnly"
    }
    private_endpoints = {
      primary = {
        application_security_group_associations = {
          primary = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/applicationSecurityGroups/asg-test"
        }
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
      }
    }
    private_endpoints_manage_dns_zone_group = false
  }

  assert {
    condition     = length(azurerm_management_lock.private_endpoint) == 1
    error_message = "The Container Registry lock should be inherited by its private endpoint."
  }

  assert {
    condition     = azurerm_management_lock.private_endpoint["primary"].lock_level == "ReadOnly"
    error_message = "The private endpoint should inherit the Container Registry lock level."
  }

  assert {
    condition     = azurerm_management_lock.private_endpoint["primary"].name == "lock-ReadOnly"
    error_message = "An inherited private endpoint lock should have a default name based on its kind."
  }

  assert {
    condition     = azurerm_management_lock.private_endpoint["primary"].scope == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["primary"].id
    error_message = "The lock should target the private endpoint whose DNS zone group is managed externally."
  }

  assert {
    condition     = azurerm_private_endpoint_application_security_group_association.this["primary-primary"].private_endpoint_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["primary"].id
    error_message = "The application security group association should target the private endpoint whose DNS zone group is managed externally."
  }
}

run "explicit_lock_overrides_inherited_lock" {
  command   = apply
  state_key = "explicit-lock-overrides-inherited-lock"

  variables {
    lock = {
      kind = "ReadOnly"
    }
    private_endpoints = {
      primary = {
        lock = {
          kind = "CanNotDelete"
        }
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
      }
    }
  }

  assert {
    condition     = azurerm_management_lock.private_endpoint["primary"].lock_level == "CanNotDelete"
    error_message = "An explicit private endpoint lock should take precedence over the inherited Container Registry lock."
  }
}

run "private_endpoint_lock_inheritance_disabled" {
  command   = apply
  state_key = "private-endpoint-lock-inheritance-disabled"

  variables {
    lock = {
      kind = "CanNotDelete"
    }
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
      }
    }
    private_endpoints_inherit_lock = false
  }

  assert {
    condition     = length(azurerm_management_lock.private_endpoint) == 0
    error_message = "A private endpoint lock should not be created when inheritance is disabled."
  }
}

run "invalid_private_endpoint_lock_kind" {
  command   = plan
  state_key = "invalid-private-endpoint-lock-kind"

  variables {
    private_endpoints = {
      primary = {
        lock = {
          kind = "Invalid"
        }
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
      }
    }
  }

  expect_failures = [
    var.private_endpoints,
  ]
}

run "customer_managed_key_data_source_lookup" {
  command   = apply
  state_key = "customer-managed-key-data-source-lookup"

  variables {
    customer_managed_key = {
      key_name              = "cmk-test"
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      key_version           = "abcdef0123456789abcdef0123456789"
      user_assigned_identity = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = toset(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"])
    }
    sku = "Premium"
  }

  # This is the pre-existing (pre-#120) behavior: without any direct value supplied, the module falls back to
  # its internal data source lookups for both the key and the identity.
  assert {
    condition     = length(data.azurerm_key_vault_key.this) == 1
    error_message = "The `azurerm_key_vault_key` data source should be used when `key_vault_key_id` is not supplied."
  }

  assert {
    condition     = length(data.azurerm_user_assigned_identity.this) == 1
    error_message = "The `azurerm_user_assigned_identity` data source should be used when `user_assigned_identity.client_id` is not supplied."
  }

  assert {
    condition     = azurerm_container_registry.this.encryption[0].key_vault_key_id == "${data.azurerm_key_vault_key.this[0].versionless_id}/abcdef0123456789abcdef0123456789"
    error_message = "The encryption block should use the key vault key ID resolved from the data source lookup, with the key version appended."
  }

  assert {
    condition     = azurerm_container_registry.this.encryption[0].identity_client_id == data.azurerm_user_assigned_identity.this[0].client_id
    error_message = "The encryption block should use the identity client ID resolved from the data source lookup."
  }
}

run "customer_managed_key_direct_values_skip_data_lookups" {
  command   = apply
  state_key = "customer-managed-key-direct-values-skip-data-lookups"

  variables {
    customer_managed_key = {
      key_name              = "cmk-test"
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      direct_values = {
        identity_client_id = "11111111-1111-1111-1111-111111111111"
        key_vault_key_id   = "https://kv-test.vault.azure.net/keys/cmk-test/abcdef0123456789abcdef0123456789"
      }
      user_assigned_identity = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = toset(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"])
    }
    sku = "Premium"
  }

  # This is the new (#120) behavior: when direct values are supplied, the module must not read them back through
  # its internal data sources, so a key/identity created in the same apply as this module doesn't fail at plan time.
  assert {
    condition     = length(data.azurerm_key_vault_key.this) == 0
    error_message = "The `azurerm_key_vault_key` data source should be skipped when `direct_values` is supplied."
  }

  assert {
    condition     = length(data.azurerm_user_assigned_identity.this) == 0
    error_message = "The `azurerm_user_assigned_identity` data source should be skipped when `direct_values` is supplied."
  }

  assert {
    condition     = azurerm_container_registry.this.encryption[0].key_vault_key_id == "https://kv-test.vault.azure.net/keys/cmk-test/abcdef0123456789abcdef0123456789"
    error_message = "The encryption block should use the directly supplied `key_vault_key_id` as-is."
  }

  assert {
    condition     = azurerm_container_registry.this.encryption[0].identity_client_id == "11111111-1111-1111-1111-111111111111"
    error_message = "The encryption block should use the directly supplied `user_assigned_identity.client_id` as-is."
  }
}

run "customer_managed_key_unknown_direct_values" {
  command = plan

  module {
    source = "./tests/fixtures/cmk-direct-values"
  }
}

run "customer_managed_key_direct_versionless_id_with_key_version" {
  command   = apply
  state_key = "customer-managed-key-direct-versionless-id-with-key-version"

  variables {
    customer_managed_key = {
      key_name              = "cmk-test"
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      key_version           = "abcdef0123456789abcdef0123456789"
      direct_values = {
        identity_client_id = "11111111-1111-1111-1111-111111111111"
        key_vault_key_id   = "https://kv-test.vault.azure.net/keys/cmk-test"
      }
      user_assigned_identity = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"
      }
    }
    managed_identities = {
      user_assigned_resource_ids = toset(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-test"])
    }
    sku = "Premium"
  }

  # `key_version` should still combine with a directly supplied *versionless* `key_vault_key_id`, mirroring how it
  # combines with the data-source-resolved versionless ID.
  assert {
    condition     = azurerm_container_registry.this.encryption[0].key_vault_key_id == "https://kv-test.vault.azure.net/keys/cmk-test/abcdef0123456789abcdef0123456789"
    error_message = "A versionless `key_vault_key_id` should have `key_version` appended, the same way the data-source lookup path does."
  }
}

run "invalid_customer_managed_key_key_vault_key_id_format" {
  command   = plan
  state_key = "invalid-customer-managed-key-key-vault-key-id-format"

  variables {
    customer_managed_key = {
      key_name              = "cmk-test"
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      direct_values = {
        identity_client_id = "11111111-1111-1111-1111-111111111111"
        key_vault_key_id   = "not-a-valid-key-id"
      }
    }
    sku = "Premium"
  }

  expect_failures = [
    var.customer_managed_key,
  ]
}

run "ambiguous_customer_managed_key_version_and_versioned_key_vault_key_id" {
  command   = plan
  state_key = "ambiguous-customer-managed-key-version-and-versioned-key-vault-key-id"

  variables {
    customer_managed_key = {
      key_name              = "cmk-test"
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
      key_version           = "11111111111111111111111111111111"
      direct_values = {
        identity_client_id = "11111111-1111-1111-1111-111111111111"
        key_vault_key_id   = "https://kv-test.vault.azure.net/keys/cmk-test/abcdef0123456789abcdef0123456789"
      }
    }
    sku = "Premium"
  }

  expect_failures = [
    var.customer_managed_key,
  ]
}
