resource "azurerm_container_registry_credential_set" "this" {
  count = var.credential_set != null ? 1 : 0

  container_registry_id = var.container_registry_id
  login_server          = var.credential_set.login_server
  name                  = var.credential_set.name

  authentication_credentials {
    password_secret_id = var.credential_set.password_secret_id
    username_secret_id = var.credential_set.username_secret_id
  }
  identity {
    type = "SystemAssigned"
  }
}
