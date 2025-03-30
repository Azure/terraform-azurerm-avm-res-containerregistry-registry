module "scope_maps" {
  source   = "./modules/scope-map"
  for_each = var.scope_maps

  name                    = each.value.name
  container_registry_name = azurerm_container_registry.this.name
  resource_group_name     = azurerm_container_registry.this.resource_group_name
  actions                 = each.value.actions
  description             = each.value.description
  registry_tokens         = each.value.registry_tokens
}