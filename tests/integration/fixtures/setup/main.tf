data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location  = var.location
  name      = "rg-acr-upgrade-${random_string.suffix.result}"
  parent_id = data.azapi_client_config.current.subscription_resource_id
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
}
