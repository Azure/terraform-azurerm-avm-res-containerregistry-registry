resource "azurerm_container_registry_token" "this" {
  for_each = var.registry_tokens

  container_registry_name = var.container_registry_name
  name                    = each.value.name
  resource_group_name     = var.resource_group_name
  scope_map_id            = azurerm_container_registry_scope_map.this.id
}


resource "azurerm_container_registry_token_password" "this" {
  for_each = tomap({ for k, v in var.registry_tokens : k => v if v.passwords != null })

  container_registry_token_id = azurerm_container_registry_token.this[each.key].id

  password1 {
    expiry = each.value.passwords.password1.expiry
  }
  dynamic "password2" {
    for_each = each.value.passwords.password2 != null ? [each.value.passwords.password2] : []

    content {
      expiry = password2.value.expiry
    }
  }
}