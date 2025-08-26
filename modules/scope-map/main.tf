resource "azurerm_container_registry_scope_map" "this" {
  actions                 = var.actions
  container_registry_name = var.container_registry_name
  name                    = var.name
  resource_group_name     = var.resource_group_name
  description             = var.description
}
