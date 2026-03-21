resource "azurerm_container_registry_cache_rule" "this" {
  container_registry_id = var.container_registry_id
  name                  = var.name
  source_repo           = var.source_repository
  target_repo           = var.target_repository
  credential_set_id     = var.credential_set != null ? azurerm_container_registry_credential_set.this[0].id : null
}
