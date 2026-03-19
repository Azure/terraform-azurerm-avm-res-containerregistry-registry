variable "container_registry_id" {
  type        = string
  description = "The resource ID of the parent Container Registry."
  nullable    = false
}

variable "task" {
  type = object({
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
  })
  description = "The full task definition and optional schedule-run-now execution settings."
  nullable    = false

  validation {
    condition     = var.task.timeout_in_seconds == null ? true : var.task.timeout_in_seconds >= 300 && var.task.timeout_in_seconds <= 28800
    error_message = "The task timeout_in_seconds must be between 300 and 28800 when specified."
  }
  validation {
    condition     = var.task.agent_pool_name == null || var.task.agent_setting == null
    error_message = "Only one of `agent_pool_name` and `agent_setting` can be specified."
  }
  validation {
    condition     = var.task.base_image_trigger == null ? true : contains(["All", "Runtime"], var.task.base_image_trigger.type)
    error_message = "The base_image_trigger type must be one of `All` or `Runtime`."
  }
  validation {
    condition     = var.task.base_image_trigger == null || var.task.base_image_trigger.update_trigger_payload_type == null ? true : contains(["Default", "Token"], var.task.base_image_trigger.update_trigger_payload_type)
    error_message = "The base_image_trigger update_trigger_payload_type must be one of `Default` or `Token`."
  }
  validation {
    condition     = var.task.platform == null ? true : contains(["Linux", "Windows"], var.task.platform.os)
    error_message = "The platform os must be one of `Linux` or `Windows`."
  }
  validation {
    condition     = var.task.platform == null || var.task.platform.architecture == null ? true : contains(["amd64", "x86", "386", "arm", "arm64"], var.task.platform.architecture)
    error_message = "The platform architecture must be one of `amd64`, `x86`, `386`, `arm`, or `arm64`."
  }
  validation {
    condition     = var.task.platform == null || var.task.platform.variant == null ? true : contains(["v6", "v7", "v8"], var.task.platform.variant)
    error_message = "The platform variant must be one of `v6`, `v7`, or `v8`."
  }
  validation {
    condition     = var.task.registry_credential == null || var.task.registry_credential.source == null ? true : contains(["None", "Default"], var.task.registry_credential.source.login_mode)
    error_message = "The registry_credential source login_mode must be one of `None` or `Default`."
  }
  validation {
    condition     = alltrue([for _, v in var.task.source_triggers : contains(["Github", "VisualStudioTeamService"], v.source_type)])
    error_message = "Each source_trigger source_type must be one of `Github` or `VisualStudioTeamService`."
  }
  validation {
    condition = alltrue([
      for _, v in var.task.source_triggers :
      length(setsubtract(v.events, toset(["commit", "pullrequest"]))) == 0
    ])
    error_message = "Each source_trigger events set may only include `commit` and `pullrequest`."
  }
  validation {
    condition = alltrue([
      for _, v in var.task.source_triggers :
      v.authentication == null || contains(["PAT", "OAuth"], v.authentication.token_type)
    ])
    error_message = "Each source_trigger authentication token_type must be one of `PAT` or `OAuth`."
  }
}
