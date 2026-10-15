module "scope_maps" {
  source   = "./modules/scope-map"
  for_each = var.scope_maps

  actions                 = each.value.actions
  container_registry_name = azurerm_container_registry.this.name
  description             = each.value.description
  location                = var.location
  name                    = each.value.name
  resource_group_name     = azurerm_container_registry.this.resource_group_name
  enable_telemetry        = var.enable_telemetry
  registry_tokens         = each.value.registry_tokens
}
