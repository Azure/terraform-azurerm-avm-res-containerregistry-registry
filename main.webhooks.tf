resource "azurerm_container_registry_webhook" "this" {
  for_each = var.webhooks

  actions             = each.value.actions
  location            = azurerm_container_registry.this.location
  name                = each.value.name
  registry_name       = azurerm_container_registry.this.name
  resource_group_name = azurerm_container_registry.this.resource_group_name
  service_uri         = each.value.service_uri
  custom_headers      = each.value.custom_headers
  scope               = each.value.scope
  status              = each.value.status
  tags                = each.value.tags

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

