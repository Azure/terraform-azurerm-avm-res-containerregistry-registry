variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "name" {
  type        = string  
  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    error_message = "The name must be between 5 and 50 characters long and can only contain lowercase letters and numbers."
  }
  description = "The name of the Container Registry."
}

variable "location" {
  type        = string  
  default     = null
  description = "The Azure location where the resources will be deployed.  If null, the location of the provided resource group will be used."
}

variable "sku" {
  type        = string
  default     = "Premium"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The SKU name must be either `Basic`, `Standard` or `Premium`."
  }
  description = "The SKU name of the Container Registry. Default is `Premium`. `Possible values are `Basic`, `Standard` and `Premium`."
}

variable "admin_enabled" {
  type        = bool  
  default     = false
  description = "Specifies whether the admin user is enabled. Defaults to `false`."
}

variable "tags" {
  type        = map(any)  
  default     = null
  description = "Map of tags to assign to the Container Registry resource."
}

variable "public_network_access_enabled" {
  type        = bool  
  default     = true
  description = "Specifies whether public access is permitted."
}


variable "quarantine_policy_enabled" {
  type        = bool  
  default     = false
  description = "Specifies whether the quarantine policy is enabled."
}

variable "zone_redundancy_enabled" {
  type        = bool  
  default     = true
  description = "Specifies whether zone redundancy is enabled.  Modifying this forces a new resource to be created."
}

variable "export_policy_enabled" {
  type        = bool  
  default     = true
  description = "Specifies whether export policy is enabled. Defaults to true. In order to set it to false, make sure the public_network_access_enabled is also set to false."
}

variable "anonymous_pull_enabled" {
  type        = bool  
  default     = false
  description = "Specifies whether anonymous (unauthenticated) pull access to this Container Registry is allowed.  Requries Standard or Premium SKU."
}

variable "data_endpoint_enabled" {
  type        = bool  
  default     = false
  description = "Specifies whether to enable dedicated data endpoints for this Container Registry.  Requires Premium SKU."
}

variable "network_rule_bypass_option" {
  type    = string
  default = "None"
  validation {
    condition     = var.network_rule_bypass_option == null ? true : contains(["AzureServices", "None"], var.network_rule_bypass_option)
    error_message = "The network_rule_bypass_option variable must be either `AzureServices` or `None`."
  }
  description = <<DESCRIPTION
Specifies whether to allow trusted Azure services access to a network restricted Container Registry.  
Possible values are `None` and `AzureServices`. Defaults to `None`.
DESCRIPTION
}

variable "georeplications" {
  type = list(object({
    location                  = string
    regional_endpoint_enabled = optional(bool, true)
    zone_redundancy_enabled   = optional(bool, true)
    tags                      = optional(map(any), null)
  }))  
  default     = []
  description = "A map of locations where the Container Registry should be geo-replicated."
}

variable "network_rule_set" {
  type = object({
    default_action = optional(string, "Deny")
    ip_rule = optional(list(object({
      # since the `action` property only permits `Allow`, this is hard-coded.
      action   = optional(string, "Allow")
      ip_range = string
    })), [])
    virtual_network = optional(list(object({
      # since the `action` property only permits `Allow`, this is hard-coded.
      action    = optional(string, "Allow")
      subnet_id = string
    })), [])
  })
  default     = null
  validation {
    condition     = var.network_rule_set == null ? true : contains(["Allow", "Deny"], var.network_rule_set.default_action)
    error_message = "The default_action value must be either `Allow` or `Deny`."
  }
  description = <<DESCRIPTION
The network rule set configuration for the Container Registry.
Requires Premium SKU.

- `default_action` - (Optional) The default action when no rule matches. Possible values are `Allow` and `Deny`. Defaults to `Deny`.
- `ip_rules` - (Optional) A list of IP rules in CIDR format. Defaults to `[]`.
  - `action` - Only "Allow" is permitted
  - `ip_range` - The CIDR block from which requests will match the rule.
- `virtual_network` - (Optional) When using with Service Endpoints, a list of subnet IDs to associate with the Container Registry. Defaults to `[]`.
  - `action` - Only "Allow" is permitted
  - `subnet_id` - The subnet id from which requests will match the rule.

DESCRIPTION
}

variable "retention_policy" {
  type = object({
    days    = optional(number, 7)
    enabled = optional(bool, false)
  })
  default     = {}
  description = <<DESCRIPTION
If enabled, this retention policy will purge an untagged manifest after a specified number of days.  

- `days` - (Optional) The number of days before the policy Defaults to 7 days.
- `enabled` - (Optional) Whether the retention policy is enabled.  Defaults to false.

DESCRIPTION
}

variable "identity" {
  type = object({
    type         = optional(string, "SystemAssigned")
    identity_ids = optional(set(string), [])
  })
  default = {}
  validation {
    condition     = var.identity.type == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
    error_message = "The default_action value must be either `SystemAssigned`, `UserAssigned` or `SystemAssigned, UserAssigned`."
  }
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })  
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
  description = "The lock level to apply to the Container Registry. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      name = optional(string, null)
      kind = optional(string, "None")
    }), {})
    tags                                    = optional(map(any), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Container Registry.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
}
