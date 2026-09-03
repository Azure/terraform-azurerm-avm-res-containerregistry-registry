variable "cache_rules" {
  type = map(object({
    name                       = string
    source_repository          = string
    target_repository          = string
    credential_set_key         = optional(string)
    credential_set_resource_id = optional(string)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Container Registry cache rules. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time. Cache rules require the **Premium** SKU.

Each object supports the following:

- `name` - (Required) The name of the cache rule. 5-50 characters, letters, numbers and hyphens.
- `source_repository` - (Required) The fully-qualified upstream source repository, including the registry host, e.g. `docker.io/library/nginx` (Docker Hub) or `mcr.microsoft.com/mcr/hello-world` (Microsoft Container Registry).
- `target_repository` - (Required) The target repository in this registry where cached images are stored, e.g. `nginx`.
- `credential_set_key` - (Optional) Key of a module-managed credential set in `var.credential_sets`. Multiple cache rules can reference the same key.
- `credential_set_resource_id` - (Optional) ARM resource ID of an existing credential set managed outside this module.

> [!NOTE]
> `credential_set_key` and `credential_set_resource_id` are mutually exclusive. When a module-managed credential set is referenced, its system-assigned managed identity must be granted read access to the referenced Key Vault secrets (for example the `Key Vault Secrets User` role). This is the **caller's responsibility**; use the matching key in the `credential_sets` output to obtain its `principal_id`. See the `cache-rules` example.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for cache_rule in values(var.cache_rules) :
      !(cache_rule.credential_set_key != null && cache_rule.credential_set_resource_id != null)
    ])
    error_message = "Each cache rule may set only one of `credential_set_key` or `credential_set_resource_id`."
  }
}

variable "credential_sets" {
  type = map(object({
    name         = string
    login_server = string
    auth_credentials = list(object({
      name                       = optional(string, "Credential1")
      username_secret_identifier = string
      password_secret_identifier = string
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
A map of registry-level credential sets that cache rules can share. The map key is deliberately arbitrary and is referenced by `cache_rules[*].credential_set_key`.

- `name` - (Required) The name of the credential set. Names must be unique across this map, ignoring case.
- `login_server` - (Required) The upstream login server the credentials authenticate to, e.g. `docker.io`. Changing this value replaces the credential set, creates a new `principal_id`, and requires the caller to update any Key Vault role assignment for that identity.
- `auth_credentials` - (Required) A list of authentication credentials (usually one). Each has:
  - `name` - (Optional) The credential name. Defaults to `Credential1`.
  - `username_secret_identifier` - (Required) Key Vault secret URI holding the upstream username.
  - `password_secret_identifier` - (Required) Key Vault secret URI holding the upstream password.

The system-assigned managed identity of each credential set must be granted read access to its referenced Key Vault secrets. This is the caller's responsibility; use the matching key in the `credential_sets` output to obtain its `principal_id`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = length(distinct([for credential_set in values(var.credential_sets) : lower(credential_set.name)])) == length(var.credential_sets)
    error_message = "Each entry in `credential_sets` must have a unique `name` (case-insensitive)."
  }
}

variable "ignore_body_changes" {
  type = object({
    cache_rule = optional(object({
      this = optional(list(string), [])
    }), {})
    credential_set = optional(object({
      this = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Body paths to ignore on the cache rule and credential set child resources, in dot notation. Use this to suppress plan diffs for properties mutated outside Terraform, such as those set by Azure Policy.

- `cache_rule.this` - Paths to ignore on each `Microsoft.ContainerRegistry/registries/cacheRules` resource.
- `credential_set.this` - Paths to ignore on each `Microsoft.ContainerRegistry/registries/credentialSets` resource.

Because the value is held in provider private state, a change only takes effect after an apply. Adding a path still shows the pending diff in the same plan, and removing one does not resurface the suppressed diff until the next plan.
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
