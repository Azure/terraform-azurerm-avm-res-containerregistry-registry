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

run "private_endpoint_defaults_to_the_registry_subresource" {
  command   = apply
  state_key = "private-endpoint-default-subresource"

  variables {
    private_endpoints = {
      primary = {
        ip_configurations = {
          primary = {
            name               = "ipconfig-default"
            private_ip_address = "10.0.0.4"
          }
        }
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
      }
    }
  }

  assert {
    condition     = azurerm_private_endpoint.this["primary"].private_service_connection[0].subresource_names[0] == "registry"
    error_message = "Omitting subresource_name should keep targeting the registry subresource, unchanged from earlier versions."
  }

  assert {
    condition     = azurerm_private_endpoint.this["primary"].ip_configuration[0].member_name == "registry"
    error_message = "Omitting subresource_name should keep the IP configuration member name unchanged."
  }
}

run "private_endpoint_honours_an_explicit_subresource_name" {
  command   = apply
  state_key = "private-endpoint-explicit-subresource"

  variables {
    private_endpoints = {
      primary = {
        ip_configurations = {
          primary = {
            name               = "ipconfig-explicit"
            private_ip_address = "10.0.0.5"
          }
        }
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        subresource_name   = "registry_data_australiaeast"
      }
    }
  }

  assert {
    condition     = azurerm_private_endpoint.this["primary"].private_service_connection[0].subresource_names[0] == "registry_data_australiaeast"
    error_message = "An explicit subresource_name should reach the private service connection."
  }

  assert {
    condition     = azurerm_private_endpoint.this["primary"].ip_configuration[0].subresource_name == "registry_data_australiaeast"
    error_message = "An explicit subresource_name should reach the IP configuration."
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
