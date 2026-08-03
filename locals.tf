locals {
  customer_managed_key_key_vault_key_id = var.customer_managed_key == null ? null : (
    var.customer_managed_key.direct_values != null
    ? (
      var.customer_managed_key.key_version != null
      ? "${var.customer_managed_key.direct_values.key_vault_key_id}/${var.customer_managed_key.key_version}"
      : var.customer_managed_key.direct_values.key_vault_key_id
    )
    : (
      var.customer_managed_key.key_version != null
      ? "${data.azurerm_key_vault_key.this[0].versionless_id}/${var.customer_managed_key.key_version}"
      : data.azurerm_key_vault_key.this[0].versionless_id
    )
  )
  customer_managed_key_identity_client_id = var.customer_managed_key == null ? null : (
    var.customer_managed_key.direct_values != null
    ? var.customer_managed_key.direct_values.identity_client_id
    : (
      var.customer_managed_key.user_assigned_identity == null
      ? null
      : data.azurerm_user_assigned_identity.this[0].client_id
    )
  )
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  ordered_geo_replications = { for geo in var.georeplications : geo.location => geo }
  # Private endpoint application security group associations
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  private_endpoint_locks = {
    for pe_key, pe_value in var.private_endpoints : pe_key => pe_value.lock != null ? pe_value.lock : var.lock
    if pe_value.lock != null || (var.private_endpoints_inherit_lock && var.lock != null)
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
