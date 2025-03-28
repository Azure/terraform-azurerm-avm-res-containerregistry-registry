resource "azurerm_container_registry_scope_map" "this" {
  name                    = var.name
  container_registry_name = var.container_registry_name
  resource_group_name     = var.resource_group_name
  actions                 = var.actions
  description             = var.description
}