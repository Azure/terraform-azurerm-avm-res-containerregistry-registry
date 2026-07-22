variable "admin_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether the admin user is enabled. Defaults to `false`."
}

variable "agent_pools" {
  type = map(object({
    name                      = string
    location                  = optional(string, null)
    instance_count            = optional(number, null)
    tier                      = optional(string, null)
    virtual_network_subnet_id = optional(string, null)
    tags                      = optional(map(string), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of agent pools to create on the Container Registry. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Required) The name of the agent pool. Must be between 3 and 20 characters long and can only contain letters and numbers.
- `location` - (Optional) The Azure location where the agent pool will be deployed. Defaults to the location of the Container Registry.
- `instance_count` - (Optional) The number of agent instances to use.
- `tier` - (Optional) The tier of the agent pool. Possible values are `S1`, `S2`, `S3`, and `I6`.
- `virtual_network_subnet_id` - (Optional) The subnet resource ID to use for network isolation.
- `tags` - (Optional) A mapping of tags to assign to the agent pool.
DESCRIPTION

  validation {
    condition     = alltrue([for _, v in var.agent_pools : can(regex("^[[:alnum:]]{3,20}$", v.name))])
    error_message = "Each agent pool `name` must be between 3 and 20 characters long and contain only letters and numbers."
  }
  validation {
    condition     = alltrue([for _, v in var.agent_pools : v.tier == null ? true : contains(["S1", "S2", "S3", "I6"], v.tier)])
    error_message = "Each agent pool `tier` must be one of `S1`, `S2`, `S3`, or `I6`."
  }
  validation {
    condition     = alltrue([for _, v in var.agent_pools : v.instance_count == null ? true : v.instance_count >= 1])
    error_message = "Each agent pool `instance_count` must be greater than or equal to 1 when specified."
  }
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

variable "network_rule_bypass_for_tasks_enabled" {
  type        = bool
  default     = false
  description = "Whether to allow Container Registry Tasks to access a network-restricted Container Registry. Defaults to `false`."
  nullable    = false
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
The number of days to retain untagged manifests. Only applicable for Premium SKU.
Set to `null` to disable the retention policy. Defaults to `7`.

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

variable "tasks" {
  type = map(object({
    name               = string
    agent_pool_name    = optional(string, null)
    enabled            = optional(bool, true)
    is_system_task     = optional(bool, false)
    log_template       = optional(string, null)
    tags               = optional(map(string), null)
    timeout_in_seconds = optional(number, null)

    agent_setting = optional(object({
      cpu = number
    }), null)

    identity = optional(object({
      type         = string
      identity_ids = optional(set(string), [])
    }), null)

    platform = optional(object({
      os           = string
      architecture = optional(string, null)
      variant      = optional(string, null)
    }), null)

    docker_step = optional(object({
      context_access_token = string
      context_path         = string
      dockerfile_path      = string
      arguments            = optional(map(string), null)
      image_names          = optional(list(string), null)
      cache_enabled        = optional(bool, null)
      push_enabled         = optional(bool, null)
      secret_arguments     = optional(map(string), null)
      target               = optional(string, null)
    }), null)

    encoded_step = optional(object({
      task_content         = string
      context_access_token = optional(string, null)
      context_path         = optional(string, null)
      secret_values        = optional(map(string), null)
      value_content        = optional(string, null)
      values               = optional(map(string), null)
    }), null)

    file_step = optional(object({
      task_file_path       = string
      context_access_token = optional(string, null)
      context_path         = optional(string, null)
      secret_values        = optional(map(string), null)
      value_file_path      = optional(string, null)
      values               = optional(map(string), null)
    }), null)

    base_image_trigger = optional(object({
      name                        = string
      type                        = string
      enabled                     = optional(bool, true)
      update_trigger_endpoint     = optional(string, null)
      update_trigger_payload_type = optional(string, null)
    }), null)

    source_triggers = optional(map(object({
      name           = string
      events         = set(string)
      repository_url = string
      source_type    = string
      branch         = optional(string, null)
      enabled        = optional(bool, true)
      authentication = optional(object({
        token             = string
        token_type        = string
        expire_in_seconds = optional(number, null)
        refresh_token     = optional(string, null)
        scope             = optional(string, null)
      }), null)
    })), {})

    timer_triggers = optional(map(object({
      name     = string
      schedule = string
      enabled  = optional(bool, true)
    })), {})

    registry_credential = optional(object({
      source = optional(object({
        login_mode = string
      }), null)
      custom = optional(map(object({
        login_server = string
        identity     = optional(string, null)
        username     = optional(string, null)
        password     = optional(string, null)
      })), {})
    }), null)

    timeouts = optional(object({
      create = optional(string, null)
      read   = optional(string, null)
      update = optional(string, null)
      delete = optional(string, null)
    }), null)

    schedule_run_now = optional(object({
      enabled = optional(bool, false)
      timeouts = optional(object({
        create = optional(string, null)
        read   = optional(string, null)
        delete = optional(string, null)
      }), null)
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Container Registry tasks to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Required) The name of the task.
- `agent_pool_name` - (Optional) The name of the dedicated agent pool for this task.
- `agent_setting` - (Optional) Agent settings for this task.
  - `cpu` - (Required) The number of cores required for the task. Supported value is `2`.
- `enabled` - (Optional) Should this task be enabled. Defaults to `true`.
- `is_system_task` - (Optional) Whether this is a system task. Defaults to `false`.
- `log_template` - (Optional) The template that describes the run log artifact.
- `timeout_in_seconds` - (Optional) Timeout in seconds for task runs. Valid range is `300` to `28800`.
- `identity` - (Optional) Managed identity settings for the task.
- `platform` - (Optional) Platform settings for the task. Required for non-system tasks.
- `docker_step` / `encoded_step` / `file_step` - (Optional) One and only one step block must be defined for non-system tasks.
- `base_image_trigger` - (Optional) Base image trigger configuration.
- `source_triggers` - (Optional) A map of source triggers.
- `timer_triggers` - (Optional) A map of timer triggers.
- `registry_credential` - (Optional) Registry credential settings.
- `tags` - (Optional) A mapping of tags to assign to the task.
- `schedule_run_now` - (Optional) Single-shot run-now configuration.
  - `enabled` - (Optional) If true, triggers an immediate schedule run when created or replaced.
DESCRIPTION

  validation {
    condition     = alltrue([for _, v in var.tasks : v.timeout_in_seconds == null ? true : v.timeout_in_seconds >= 300 && v.timeout_in_seconds <= 28800])
    error_message = "Each task timeout_in_seconds must be between 300 and 28800 when specified."
  }
  validation {
    condition     = alltrue([for _, v in var.tasks : v.agent_pool_name == null || v.agent_setting == null])
    error_message = "For each task, only one of `agent_pool_name` and `agent_setting` can be specified."
  }
  validation {
    condition     = alltrue([for _, v in var.tasks : v.base_image_trigger == null ? true : contains(["All", "Runtime"], v.base_image_trigger.type)])
    error_message = "Each task base_image_trigger type must be one of `All` or `Runtime`."
  }
  validation {
    condition     = alltrue([for _, v in var.tasks : v.base_image_trigger == null || v.base_image_trigger.update_trigger_payload_type == null ? true : contains(["Default", "Token"], v.base_image_trigger.update_trigger_payload_type)])
    error_message = "Each task base_image_trigger update_trigger_payload_type must be one of `Default` or `Token`."
  }
  validation {
    condition     = alltrue([for _, v in var.tasks : v.platform == null ? true : contains(["Linux", "Windows"], v.platform.os)])
    error_message = "Each task platform os must be one of `Linux` or `Windows`."
  }
  validation {
    condition     = alltrue([for _, v in var.tasks : v.platform == null || v.platform.architecture == null ? true : contains(["amd64", "x86", "386", "arm", "arm64"], v.platform.architecture)])
    error_message = "Each task platform architecture must be one of `amd64`, `x86`, `386`, `arm`, or `arm64`."
  }
  validation {
    condition     = alltrue([for _, v in var.tasks : v.platform == null || v.platform.variant == null ? true : contains(["v6", "v7", "v8"], v.platform.variant)])
    error_message = "Each task platform variant must be one of `v6`, `v7`, or `v8`."
  }
  validation {
    condition     = alltrue([for _, v in var.tasks : v.registry_credential == null || v.registry_credential.source == null ? true : contains(["None", "Default"], v.registry_credential.source.login_mode)])
    error_message = "Each task registry_credential source login_mode must be one of `None` or `Default`."
  }
  validation {
    condition     = alltrue(flatten([for _, v in var.tasks : [for _, st in v.source_triggers : contains(["Github", "VisualStudioTeamService"], st.source_type)]]))
    error_message = "Each task source_trigger source_type must be one of `Github` or `VisualStudioTeamService`."
  }
  validation {
    condition = alltrue(flatten([
      for _, v in var.tasks : [
        for _, st in v.source_triggers : length(setsubtract(st.events, toset(["commit", "pullrequest"]))) == 0
      ]
    ]))
    error_message = "Each task source_trigger events set may only include `commit` and `pullrequest`."
  }
  validation {
    condition = alltrue(flatten([
      for _, v in var.tasks : [
        for _, st in v.source_triggers : st.authentication == null || contains(["PAT", "OAuth"], st.authentication.token_type)
      ]
    ]))
    error_message = "Each task source_trigger authentication token_type must be one of `PAT` or `OAuth`."
  }
}

variable "zone_redundancy_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether zone redundancy is enabled.  Modifying this forces a new resource to be created."
}
