variable "name" {
  type        = string
  description = "The name of the cache rule. Must be 5-50 characters long and can only contain letters, numbers and hyphens."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{5,50}$", var.name))
    error_message = "`name` must be between 5 and 50 characters long and can only contain letters, numbers and hyphens."
  }
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
The fully-qualified ARM resource ID of the Container Registry into which this cache rule will be deployed (e.g. `/subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/myregistry`). This submodule **does not** create the parent registry.
DESCRIPTION
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.ContainerRegistry/registries", var.parent_id))
    error_message = "`parent_id` must be a valid `Microsoft.ContainerRegistry/registries` resource ID."
  }
}

variable "source_repository" {
  type        = string
  description = <<DESCRIPTION
The source repository pulled from the upstream registry. This **must** be the fully-qualified upstream path, including the registry host, for example `docker.io/library/nginx` for Docker Hub or `mcr.microsoft.com/mcr/hello-world` for Microsoft Container Registry.
DESCRIPTION
  nullable    = false
}

variable "target_repository" {
  type        = string
  description = "The target repository in the Container Registry where cached images are stored, for example `nginx` (used as `<registry>.azurecr.io/nginx:<tag>`)."
  nullable    = false
}

variable "credential_set_resource_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Optional ARM resource ID of a credential set (`Microsoft.ContainerRegistry/registries/credentialSets`) used to authenticate to the upstream registry. Required for rate-limited or private upstreams such as Docker Hub; omit for public upstreams such as Microsoft Container Registry.
DESCRIPTION
}

variable "ignore_body_changes" {
  type = object({
    this = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body paths to ignore for each `azapi_resource` this submodule manages, in dot notation. Use this to suppress plan diffs for properties mutated outside Terraform.

- `this` - Paths to ignore on the `Microsoft.ContainerRegistry/registries/cacheRules` resource.

Because the value is held in provider private state, a change only takes effect after an apply.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    this = optional(string, "Microsoft.ContainerRegistry/registries/cacheRules@2025-11-01")
  })
  default     = {}
  description = <<DESCRIPTION
A map controlling the AzAPI resource type (and API version) used for each `azapi_resource` this submodule manages.

- `this` - The `Microsoft.ContainerRegistry/registries/cacheRules` resource type and API version to use.
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
Retry configuration applied to the cache rule `azapi` resource. Defaults to `null` (no custom retry).

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
Per-operation timeouts applied to the cache rule `azapi` resource. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).
DESCRIPTION
}
