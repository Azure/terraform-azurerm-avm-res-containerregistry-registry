variable "auth_credentials" {
  type = list(object({
    name                       = optional(string, "Credential1")
    username_secret_identifier = string
    password_secret_identifier = string
  }))
  description = <<DESCRIPTION
A list of authentication credentials the credential set stores for the upstream registry. Usually a single primary credential.

- `name` - (Optional) The name of the credential. Defaults to `Credential1` (the only value currently supported by Azure).
- `username_secret_identifier` - (Required) The Key Vault secret URI that holds the upstream registry username.
- `password_secret_identifier` - (Required) The Key Vault secret URI that holds the upstream registry password.

The system-assigned managed identity of this credential set (exposed via the `principal_id` output) must be granted read access to the referenced Key Vault secrets (for example the `Key Vault Secrets User` role).
DESCRIPTION
  nullable    = false

  validation {
    condition     = length(var.auth_credentials) > 0
    error_message = "`auth_credentials` must contain at least one credential."
  }
}

variable "name" {
  type        = string
  description = "The name of the credential set. Must be 5-50 characters long and can only contain letters, numbers and hyphens."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{5,50}$", var.name))
    error_message = "`name` must be between 5 and 50 characters long and can only contain letters, numbers and hyphens."
  }
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
The fully-qualified ARM resource ID of the Container Registry into which this credential set will be deployed (e.g. `/subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/myregistry`). This submodule **does not** create the parent registry.
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.ContainerRegistry/registries", var.parent_id))
    error_message = "`parent_id` must be a valid `Microsoft.ContainerRegistry/registries` resource ID."
  }
}

variable "login_server" {
  type        = string
  default     = null
  description = "The login server of the upstream registry the credentials authenticate to (e.g. `docker.io` for Docker Hub)."
}

variable "resource_types" {
  type = object({
    this = optional(string, "Microsoft.ContainerRegistry/registries/credentialSets@2025-11-01")
  })
  default     = {}
  description = <<DESCRIPTION
A map controlling the AzAPI resource type (and API version) used for each `azapi_resource` this submodule manages.

- `this` - The `Microsoft.ContainerRegistry/registries/credentialSets` resource type and API version to use.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to the credential set `azapi` resource. Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) Regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Per-operation timeouts applied to the credential set `azapi` resource. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).
DESCRIPTION
}
