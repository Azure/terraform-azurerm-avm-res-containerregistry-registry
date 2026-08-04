resource "azapi_resource" "this" {
  type      = var.resource_types.this
  name      = var.name
  parent_id = var.parent_id

  body = {
    identity = {
      type = "SystemAssigned"
    }
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

  # loginServer identifies the upstream the credentials belong to; changing it
  # re-targets the credential set and requires replacement.
  replace_triggers_refs = [
    "properties.loginServer",
  ]

  # Export the system-assigned identity so callers can grant it Key Vault access.
  response_export_values = [
    "identity.principalId",
    "identity.tenantId",
  ]

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
