terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0, < 3.0"
    }
  }
}
