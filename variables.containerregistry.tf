variable "admin_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether the admin user is enabled. Defaults to `false`."
}

variable "anonymous_pull_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether anonymous (unauthenticated) pull access to this Container Registry is allowed.  Requries Standard or Premium SKU."
}

variable "cache_rules" {
  type = map(object({
    name              = string
    source_repository = string
    target_repository = string
    credential_set = optional(object({
      name               = string
      login_server       = string
      username_secret_id = string
      password_secret_id = string
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of cache rules to create on the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
Cache rules allow you to cache container images from public registries (e.g., Docker Hub, MCR) in your Azure Container Registry for faster and more reliable access.
Requires Premium SKU.

- `name` - (Required) The name of the cache rule.
- `source_repository` - (Required) The source repository path to cache from (e.g., 'library/hello-world' for Docker Hub, 'mcr.microsoft.com/dotnet/aspnet' for MCR).
- `target_repository` - (Required) The target repository path in your registry where the cached image will be stored.
- `credential_set` - (Optional) Credential set configuration for authenticated pulls from the source registry. Required for Docker Hub due to rate limits. Not required for public registries like MCR.
  - `name` - (Required) The name of the credential set.
  - `login_server` - (Required) The external registry login server (e.g., 'docker.io' for Docker Hub).
  - `username_secret_id` - (Required) The Key Vault secret ID containing the username.
  - `password_secret_id` - (Required) The Key Vault secret ID containing the password.

DESCRIPTION
}

variable "data_endpoint_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether to enable dedicated data endpoints for this Container Registry.  Requires Premium SKU."
}

variable "export_policy_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether export policy is enabled. Defaults to true. In order to set it to false, make sure the public_network_access_enabled is also set to false."
}

variable "georeplications" {
  type = list(object({
    location                  = string
    regional_endpoint_enabled = optional(bool, true)
    zone_redundancy_enabled   = optional(bool, true)
    tags                      = optional(map(any), null)
  }))
  default     = []
  description = <<DESCRIPTION
A list of geo-replication configurations for the Container Registry.

- `location` - (Required) The geographic location where the Container Registry should be geo-replicated.
- `regional_endpoint_enabled` - (Optional) Enables or disables regional endpoint. Defaults to `true`.
- `zone_redundancy_enabled` - (Optional) Enables or disables zone redundancy. Defaults to `true`.
- `tags` - (Optional) A map of additional tags for the geo-replication configuration. Defaults to `null`.

DESCRIPTION
}

variable "network_rule_bypass_option" {
  type        = string
  default     = "None"
  description = <<DESCRIPTION
Specifies whether to allow trusted Azure services access to a network restricted Container Registry.
Possible values are `None` and `AzureServices`. Defaults to `None`.
DESCRIPTION

  validation {
    condition     = var.network_rule_bypass_option == null ? true : contains(["AzureServices", "None"], var.network_rule_bypass_option)
    error_message = "The network_rule_bypass_option variable must be either `AzureServices` or `None`."
  }
}

variable "network_rule_set" {
  type = object({
    default_action = optional(string, "Deny")
    ip_rule = optional(list(object({
      # since the `action` property only permits `Allow`, this is hard-coded.
      action   = optional(string, "Allow")
      ip_range = string
    })), [])
  })
  default     = null
  description = <<DESCRIPTION
The network rule set configuration for the Container Registry.
Requires Premium SKU.

- `default_action` - (Optional) The default action when no rule matches. Possible values are `Allow` and `Deny`. Defaults to `Deny`.
- `ip_rules` - (Optional) A list of IP rules in CIDR format. Defaults to `[]`.
  - `action` - Only "Allow" is permitted
  - `ip_range` - The CIDR block from which requests will match the rule.

DESCRIPTION

  validation {
    condition     = var.network_rule_set == null ? true : contains(["Allow", "Deny"], var.network_rule_set.default_action)
    error_message = "The default_action value must be either `Allow` or `Deny`."
  }
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

variable "retention_policy_in_days" {
  type        = number
  default     = 7
  description = <<DESCRIPTION
If enabled, this retention policy will purge an untagged manifest after a specified number of days.

- `days` - (Optional) The number of days before the policy Defaults to 7 days.

DESCRIPTION
}

variable "scope_maps" {
  type = map(object({
    name        = string
    actions     = list(string)
    description = optional(string, null)
    registry_tokens = optional(map(object({
      name    = string
      enabled = optional(bool, true)
      passwords = optional(object({
        password1 = object({
          expiry = optional(string)
        })
        password2 = optional(object({
          expiry = optional(string)
        }))
      }))
    })))
  }))
  default     = {}
  description = <<DESCRIPTION
A map of scope maps to create on the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `name` - The name of the scope map.
- `actions` - A list of actions that this scope map can perform. Example: "repo/content/read", "repo2/content/delete"
- `description` - The description of the scope map.
- `registry_tokens` - A map of Azure Container Registry token associated to a scope map. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - Specifies the name of the token.
  - `enabled` - Should the Container Registry token be enabled? Defaults to true.
  - `passwords` - The passwords of the token. The first password is required, the second password is optional.
    - `password1` - The first password of the token.
      - `expiry` - The expiry date of the first password. If not specified, the password will not expire.
    - `password2` - The second password of the token.
      - `expiry` - The expiry date of the second password. If not specified, the password will not expire.
DESCRIPTION
}

variable "sku" {
  type        = string
  default     = "Premium"
  description = "The SKU name of the Container Registry. Default is `Premium`. `Possible values are `Basic`, `Standard` and `Premium`."

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The SKU name must be either `Basic`, `Standard` or `Premium`."
  }
}

variable "zone_redundancy_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether zone redundancy is enabled.  Modifying this forces a new resource to be created."
}
