module "cache_rules" {
  source   = "./modules/cache-rule"
  for_each = var.cache_rules

  container_registry_id = azurerm_container_registry.this.id
  name                  = each.value.name
  source_repository     = each.value.source_repository
  target_repository     = each.value.target_repository
  credential_set        = each.value.credential_set
}
