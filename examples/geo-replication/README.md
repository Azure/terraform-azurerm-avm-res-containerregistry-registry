<!-- BEGIN_TF_DOCS -->
# Example illustrating geo-replication

This deploys a geo-replicated Container Registry.  

For information about geo-replication, see <https://learn.microsoft.com/en-us/azure/container-registry/container-registry-geo-replication>

```hcl
terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4, < 5.0.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "australiasoutheast"
  name     = module.naming.resource_group.name_unique
}

# This is the module call
module "containerregistry" {
  source = "../../"
  # source             = "Azure/avm-containerregistry-registry/azurerm"
  name                = module.naming.container_registry.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  # australiasoutheast doesn't support zone redundancy for ACR (https://learn.microsoft.com/en-us/azure/container-registry/zone-redundancy#regional-support)
  zone_redundancy_enabled = false

  georeplications = [
    {
      location = "australiaeast"
      # zone redundancy is enabled by default, and is supported in australia east
      tags = {
        environment = "prod"
        department  = "engineering"
      }
    },
    {
      location                = "australiacentral"
      zone_redundancy_enabled = false
      tags = {
        environment = "pre-prod"
        department  = "engineering"
      }
    }
  ]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4, < 5.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_containerregistry"></a> [containerregistry](#module\_containerregistry)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->