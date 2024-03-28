data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0

  name = var.resource_group_name
}

resource "azurerm_container_registry" "this" {
  location                      = coalesce(var.location, local.resource_group_location)
  name                          = var.name
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  data_endpoint_enabled         = var.data_endpoint_enabled
  export_policy_enabled         = var.export_policy_enabled
  network_rule_bypass_option    = var.network_rule_bypass_option
  public_network_access_enabled = var.public_network_access_enabled
  quarantine_policy_enabled     = var.quarantine_policy_enabled
  tags                          = var.tags
  zone_redundancy_enabled       = var.zone_redundancy_enabled

  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      tags                      = georeplications.value.tags
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
    }
  }
  dynamic "identity" {
    for_each = var.managed_identities != null ? { this = var.managed_identities } : {}
    content {
      type         = identity.value.system_assigned && length(identity.value.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(identity.value.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  # Only one network_rule_set block is allowed.
  # Create it if the variable is not null.
  dynamic "network_rule_set" {
    for_each = var.network_rule_set != null ? { this = var.network_rule_set } : {}
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rule
        content {
          action   = ip_rule.value.action
          ip_range = ip_rule.value.ip_range
        }
      }
      dynamic "virtual_network" {
        for_each = network_rule_set.value.virtual_network
        content {
          action    = virtual_network.value.action
          subnet_id = virtual_network.value.subnet_id
        }
      }
    }
  }
  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? { this = var.retention_policy } : {}
    content {
      days    = retention_policy.value.days
      enabled = retention_policy.value.enabled
    }
  }
  trust_policy {
    enabled = var.enable_trust_policy
  }

  lifecycle {
    precondition {
      condition     = var.zone_redundancy_enabled && var.sku == "Premium" || !var.zone_redundancy_enabled
      error_message = "The Premium SKU is required if zone redundancy is enabled."
    }
    precondition {
      condition     = var.network_rule_set != null && var.sku == "Premium" || var.network_rule_set == null
      error_message = "The Premium SKU is required if a network rule set is defined."
    }
  }
}

resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_container_registry.this.id
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_container_registry.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
