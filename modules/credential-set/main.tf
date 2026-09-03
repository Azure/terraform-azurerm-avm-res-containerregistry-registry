resource "azapi_resource" "this" {
  type      = var.resource_types.this
  name      = var.name
  parent_id = var.parent_id

  body = {
    properties = {
      loginServer = var.login_server
      authCredentials = [
        for credential in var.auth_credentials : {
          name                     = credential.name
          usernameSecretIdentifier = credential.username_secret_identifier
          passwordSecretIdentifier = credential.password_secret_identifier
        }
      ]
    }
  }

  # System-assigned managed identity is declared via the dedicated `identity`
  # block (a stable computed attribute stored in state), not inside `body`.
  # Declaring it in `body` makes AzAPI drop the read-only `identity.principalId`
  # on refresh, breaking idempotency for anything consuming `principal_id`.
  identity {
    type = "SystemAssigned"
  }

  ignore_body_changes = length(var.ignore_body_changes.this) > 0 ? var.ignore_body_changes.this : null
  # loginServer identifies the upstream the credentials belong to; changing it
  # re-targets the credential set and requires replacement.
  replace_triggers_refs = [
    "properties.loginServer",
  ]

  # No read-only body properties are needed; the identity principal/tenant IDs
  # are surfaced through the `identity` block attributes instead.
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
