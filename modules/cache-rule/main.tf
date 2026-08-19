resource "azapi_resource" "this" {
  type      = var.resource_types.this
  name      = var.name
  parent_id = var.parent_id

  body = {
    properties = {
      sourceRepository        = var.source_repository
      targetRepository        = var.target_repository
      credentialSetResourceId = var.credential_set_resource_id
    }
  }

  ignore_body_changes = length(var.ignore_body_changes.this) > 0 ? var.ignore_body_changes.this : null
  # Source and target repository define the cache mapping identity; changing
  # either re-targets the rule and requires replacement.
  replace_triggers_refs = [
    "properties.sourceRepository",
    "properties.targetRepository",
  ]

  response_export_values = []

  retry = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
