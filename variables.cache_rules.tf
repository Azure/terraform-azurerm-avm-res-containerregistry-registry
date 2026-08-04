variable "cache_rules" {
  type = map(object({
    name              = string
    source_repository = string
    target_repository = string
    credential_set = optional(object({
      name         = string
      login_server = optional(string)
      auth_credentials = list(object({
        name                       = optional(string, "Credential1")
        username_secret_identifier = string
        password_secret_identifier = string
      }))
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Container Registry cache rules. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time. Cache rules require the **Premium** SKU.

Each object supports the following:

- `name` - (Required) The name of the cache rule. 5-50 characters, letters, numbers and hyphens.
- `source_repository` - (Required) The fully-qualified upstream source repository, including the registry host, e.g. `docker.io/library/nginx` (Docker Hub) or `mcr.microsoft.com/mcr/hello-world` (Microsoft Container Registry).
- `target_repository` - (Required) The target repository in this registry where cached images are stored, e.g. `nginx`.
- `credential_set` - (Optional) Credential set used to authenticate to the upstream registry. Required for rate-limited or private upstreams such as Docker Hub; omit for public upstreams such as MCR.
  - `name` - (Required) The name of the credential set. 5-50 characters, letters, numbers and hyphens.
  - `login_server` - (Optional) The upstream login server the credentials authenticate to, e.g. `docker.io`.
  - `auth_credentials` - (Required) A list of authentication credentials (usually one). Each has:
    - `name` - (Optional) The credential name. Defaults to `Credential1`.
    - `username_secret_identifier` - (Required) Key Vault secret URI holding the upstream username.
    - `password_secret_identifier` - (Required) Key Vault secret URI holding the upstream password.

> [!NOTE]
> When a `credential_set` is supplied, its system-assigned managed identity must be granted read access to the referenced Key Vault secrets (for example the `Key Vault Secrets User` role). This is the **caller's responsibility**; use the `credential_sets` output's `principal_id` to create the role assignment. See the `cache-rules` example.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    cache_rule     = optional(string, "Microsoft.ContainerRegistry/registries/cacheRules@2025-11-01")
    credential_set = optional(string, "Microsoft.ContainerRegistry/registries/credentialSets@2025-11-01")
  })
  default     = {}
  description = <<DESCRIPTION
A map controlling the AzAPI resource type (and API version) used for the cache rule and credential set child resources. Override to pin a different (stable) API version.

- `cache_rule` - The `Microsoft.ContainerRegistry/registries/cacheRules` resource type and API version to use.
- `credential_set` - The `Microsoft.ContainerRegistry/registries/credentialSets` resource type and API version to use.
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
Retry configuration applied to every `azapi` resource managed by the module's cache rule and credential set submodules. Defaults to `null` (no custom retry).

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
Per-operation timeouts applied to every `azapi` resource managed by the module's cache rule and credential set submodules. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).
DESCRIPTION
}
