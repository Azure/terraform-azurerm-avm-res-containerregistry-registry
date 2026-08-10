# Credential sets are modelled as an independent child resource. Cardinality lives
# here (for_each), not on the submodule's primary resource (TFRMNFR1).
module "credential_set" {
  source   = "./modules/credential-set"
  for_each = var.credential_sets

  auth_credentials = each.value.auth_credentials
  login_server     = each.value.login_server
  name             = each.value.name
  parent_id        = azurerm_container_registry.this.id
  resource_types   = { this = var.resource_types.credential_set }
  retry            = var.retry
  timeouts         = var.timeouts
}

module "cache_rule" {
  source   = "./modules/cache-rule"
  for_each = var.cache_rules

  name              = each.value.name
  parent_id         = azurerm_container_registry.this.id
  source_repository = each.value.source_repository
  target_repository = each.value.target_repository
  # `credential_set_key` is caller-supplied and therefore known at plan time.
  # The referenced resource ID can remain computed without affecting cardinality.
  credential_set_resource_id = each.value.credential_set_key != null ? module.credential_set[each.value.credential_set_key].resource_id : each.value.credential_set_resource_id
  resource_types             = { this = var.resource_types.cache_rule }
  retry                      = var.retry
  timeouts                   = var.timeouts
}
