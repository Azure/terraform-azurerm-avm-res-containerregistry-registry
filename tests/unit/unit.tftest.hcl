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

run "diagnostic_settings_disabled_by_default" {
  command   = plan
  state_key = "diagnostic-settings-disabled-by-default"

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.this) == 0
    error_message = "Diagnostic settings should not be created unless configured."
  }
}

run "diagnostic_settings_default_metrics" {
  command   = plan
  state_key = "diagnostic-settings-default-metrics"

  variables {
    diagnostic_settings = {
      primary = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
      }
    }
  }

  assert {
    condition     = toset([for metric in azurerm_monitor_diagnostic_setting.this["primary"].enabled_metric : metric.category]) == toset(["AllMetrics"])
    error_message = "Diagnostic settings should configure AllMetrics through enabled_metric by default."
  }

  assert {
    condition     = toset([for log in azurerm_monitor_diagnostic_setting.this["primary"].enabled_log : log.category_group]) == toset(["allLogs"])
    error_message = "Diagnostic settings should continue to enable the allLogs category group by default."
  }
}

run "diagnostic_settings_metrics_only" {
  command   = plan
  state_key = "diagnostic-settings-metrics-only"

  variables {
    diagnostic_settings = {
      primary = {
        log_groups            = []
        metric_categories     = ["AllMetrics"]
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
      }
    }
  }

  assert {
    condition     = toset([for metric in azurerm_monitor_diagnostic_setting.this["primary"].enabled_metric : metric.category]) == toset(["AllMetrics"])
    error_message = "Explicit metric categories should be configured through enabled_metric without requiring logs."
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.this["primary"].enabled_log) == 0
    error_message = "A metrics-only diagnostic setting should not enable any logs."
  }
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

run "private_endpoint_subresource_with_managed_dns" {
  command   = apply
  state_key = "private-endpoint-subresource-with-managed-dns"

  variables {
    private_endpoints = {
      omitted = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
          }
        }
      }
      null_value = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        subresource_name   = null
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.5"
          }
        }
      }
      explicit = {
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io"]
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        # A distinct mock-only value proves that the input is not replaced by the registry default.
        subresource_name = "custom-subresource"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.6"
          }
        }
      }
    }
  }

  assert {
    condition = alltrue([
      for key, endpoint in azurerm_private_endpoint.this :
      endpoint.private_service_connection[0].subresource_names == tolist([key == "explicit" ? "custom-subresource" : "registry"]) &&
      endpoint.ip_configuration[0].subresource_name == (key == "explicit" ? "custom-subresource" : "registry") &&
      endpoint.ip_configuration[0].member_name == "registry"
    ])
    error_message = "Managed DNS endpoints must honor explicit subresources in connections and IP configurations, default omitted/null values to registry, and retain the registry member name."
  }

  assert {
    condition     = length(azurerm_private_endpoint.this) == 3 && length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0
    error_message = "Managed DNS must create only the three module-managed private endpoints."
  }

  assert {
    condition     = azurerm_private_endpoint.this["explicit"].private_dns_zone_group[0].name == "default"
    error_message = "The default DNS zone group name must remain unchanged."
  }

  assert {
    condition     = output.private_endpoints == tomap(azurerm_private_endpoint.this)
    error_message = "The private endpoints output must continue exposing the module-managed endpoint resources."
  }
}

run "private_endpoint_subresource_with_unmanaged_dns" {
  command   = apply
  state_key = "private-endpoint-subresource-with-unmanaged-dns"

  variables {
    private_endpoints = {
      omitted = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
          }
        }
      }
      null_value = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        subresource_name   = null
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.5"
          }
        }
      }
      explicit = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
        subresource_name   = "custom-subresource"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.6"
          }
        }
      }
    }
    private_endpoints_manage_dns_zone_group = false
  }

  assert {
    condition = alltrue([
      for key, endpoint in azurerm_private_endpoint.this_unmanaged_dns_zone_groups :
      endpoint.private_service_connection[0].subresource_names == tolist([key == "explicit" ? "custom-subresource" : "registry"]) &&
      endpoint.ip_configuration[0].subresource_name == (key == "explicit" ? "custom-subresource" : "registry") &&
      endpoint.ip_configuration[0].member_name == "registry"
    ])
    error_message = "Unmanaged DNS endpoints must honor explicit subresources in connections and IP configurations, default omitted/null values to registry, and retain the registry member name."
  }

  assert {
    condition     = length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 3 && length(azurerm_private_endpoint.this) == 0
    error_message = "Unmanaged DNS must create only the three externally managed DNS private endpoints."
  }

  assert {
    condition     = output.private_endpoints == tomap(azurerm_private_endpoint.this_unmanaged_dns_zone_groups)
    error_message = "The private endpoints output must continue exposing the externally managed DNS endpoint resources."
  }
}
