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
}

run "arm_audience_tokens_enabled_by_default" {
  command   = plan
  state_key = "arm-audience-tokens-enabled-by-default"

  assert {
    condition     = azurerm_container_registry.this.azuread_authentication_as_arm_policy_enabled == true
    error_message = "ARM audience token authentication should stay enabled by default to match the provider default."
  }
}

run "arm_audience_tokens_disabled" {
  command   = plan
  state_key = "arm-audience-tokens-disabled"

  variables {
    azuread_authentication_as_arm_policy_enabled = false
    role_assignment_mode                         = "AbacRepositoryPermissions"
  }

  assert {
    condition     = azurerm_container_registry.this.azuread_authentication_as_arm_policy_enabled == false
    error_message = "ARM audience token authentication should be disabled when the input is false."
  }

  assert {
    condition     = azurerm_container_registry.this.role_assignment_mode == "AbacRepositoryPermissions"
    error_message = "Disabling ARM audience token authentication should not change the configured role assignment mode."
  }
}

run "arm_audience_tokens_null_uses_default" {
  command   = plan
  state_key = "arm-audience-tokens-null-uses-default"

  variables {
    azuread_authentication_as_arm_policy_enabled = null
  }

  assert {
    condition     = azurerm_container_registry.this.azuread_authentication_as_arm_policy_enabled == true
    error_message = "A null input should fall back to the default of true."
  }
}
