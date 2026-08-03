data "azurerm_key_vault_key" "this" {
  count = var.customer_managed_key == null || var.customer_managed_key_direct_values != null ? 0 : 1

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  name         = var.customer_managed_key.key_name
}

data "azurerm_user_assigned_identity" "this" {
  count = var.customer_managed_key == null || var.customer_managed_key.user_assigned_identity == null || var.customer_managed_key_direct_values != null ? 0 : 1

  #/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{userAssignedIdentityName}
  name                = reverse(split("/", var.customer_managed_key.user_assigned_identity.resource_id))[0]
  resource_group_name = split("/", var.customer_managed_key.user_assigned_identity.resource_id)[4]
}
