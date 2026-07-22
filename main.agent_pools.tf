resource "azurerm_container_registry_agent_pool" "this" {
  for_each = var.agent_pools

  container_registry_name   = azurerm_container_registry.this.name
  location                  = coalesce(each.value.location, azurerm_container_registry.this.location)
  name                      = each.value.name
  resource_group_name       = azurerm_container_registry.this.resource_group_name
  instance_count            = each.value.instance_count
  tags                      = each.value.tags
  tier                      = each.value.tier
  virtual_network_subnet_id = each.value.virtual_network_subnet_id
}
