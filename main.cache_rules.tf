locals {
  # Cache rules that authenticate to their upstream via a credential set. Filtered
  # on the caller-supplied `credential_set` field, which is known at plan time, so
  # this map's keys never depend on computed values.
  cache_rules_with_credential_set = {
    for key, rule in var.cache_rules : key => rule if rule.credential_set != null
  }
}

# Credential sets are modelled as an independent child resource. Cardinality lives
# here (for_each), not on the submodule's primary resource (TFRMNFR1).
module "credential_set" {
  source   = "./modules/credential-set"
  for_each = local.cache_rules_with_credential_set

  auth_credentials = each.value.credential_set.auth_credentials
  name             = each.value.credential_set.name
  parent_id        = azurerm_container_registry.this.id
  login_server     = each.value.credential_set.login_server
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
  # `module.credential_set` is keyed by the same static cache-rule keys, so this
  # lookup key is known at plan time even though the resource ID it returns is
  # computed. This avoids a plan-time computed `for_each`/index error.
  credential_set_resource_id = each.value.credential_set != null ? module.credential_set[each.key].resource_id : null
  resource_types             = { this = var.resource_types.cache_rule }
  retry                      = var.retry
  timeouts                   = var.timeouts
}
