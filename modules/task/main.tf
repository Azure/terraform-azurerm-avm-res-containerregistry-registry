resource "azurerm_container_registry_task" "this" {
  container_registry_id = var.container_registry_id
  name                  = var.task.name
  agent_pool_name       = var.task.agent_pool_name
  enabled               = var.task.enabled
  is_system_task        = var.task.is_system_task
  log_template          = var.task.log_template
  tags                  = var.task.tags
  timeout_in_seconds    = var.task.timeout_in_seconds

  dynamic "agent_setting" {
    for_each = var.task.agent_setting == null ? [] : [var.task.agent_setting]

    content {
      cpu = agent_setting.value.cpu
    }
  }
  dynamic "base_image_trigger" {
    for_each = var.task.base_image_trigger == null ? [] : [var.task.base_image_trigger]

    content {
      name                        = base_image_trigger.value.name
      type                        = base_image_trigger.value.type
      enabled                     = base_image_trigger.value.enabled
      update_trigger_endpoint     = base_image_trigger.value.update_trigger_endpoint
      update_trigger_payload_type = base_image_trigger.value.update_trigger_payload_type
    }
  }
  dynamic "docker_step" {
    for_each = var.task.docker_step == null ? [] : [var.task.docker_step]

    content {
      context_access_token = docker_step.value.context_access_token
      context_path         = docker_step.value.context_path
      dockerfile_path      = docker_step.value.dockerfile_path
      arguments            = docker_step.value.arguments
      cache_enabled        = docker_step.value.cache_enabled
      image_names          = docker_step.value.image_names
      push_enabled         = docker_step.value.push_enabled
      secret_arguments     = docker_step.value.secret_arguments
      target               = docker_step.value.target
    }
  }
  dynamic "encoded_step" {
    for_each = var.task.encoded_step == null ? [] : [var.task.encoded_step]

    content {
      task_content         = encoded_step.value.task_content
      context_access_token = encoded_step.value.context_access_token
      context_path         = encoded_step.value.context_path
      secret_values        = encoded_step.value.secret_values
      value_content        = encoded_step.value.value_content
      values               = encoded_step.value.values
    }
  }
  dynamic "file_step" {
    for_each = var.task.file_step == null ? [] : [var.task.file_step]

    content {
      task_file_path       = file_step.value.task_file_path
      context_access_token = file_step.value.context_access_token
      context_path         = file_step.value.context_path
      secret_values        = file_step.value.secret_values
      value_file_path      = file_step.value.value_file_path
      values               = file_step.value.values
    }
  }
  dynamic "identity" {
    for_each = var.task.identity == null ? [] : [var.task.identity]

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  dynamic "platform" {
    for_each = var.task.platform == null ? [] : [var.task.platform]

    content {
      os           = platform.value.os
      architecture = platform.value.architecture
      variant      = platform.value.variant
    }
  }
  dynamic "registry_credential" {
    for_each = var.task.registry_credential == null ? [] : [var.task.registry_credential]

    content {
      dynamic "custom" {
        for_each = registry_credential.value.custom

        content {
          login_server = custom.value.login_server
          identity     = custom.value.identity
          password     = custom.value.password
          username     = custom.value.username
        }
      }
      dynamic "source" {
        for_each = registry_credential.value.source == null ? [] : [registry_credential.value.source]

        content {
          login_mode = source.value.login_mode
        }
      }
    }
  }
  dynamic "source_trigger" {
    for_each = var.task.source_triggers

    content {
      events         = source_trigger.value.events
      name           = source_trigger.value.name
      repository_url = source_trigger.value.repository_url
      source_type    = source_trigger.value.source_type
      branch         = source_trigger.value.branch
      enabled        = source_trigger.value.enabled

      dynamic "authentication" {
        for_each = source_trigger.value.authentication == null ? [] : [source_trigger.value.authentication]

        content {
          token             = authentication.value.token
          token_type        = authentication.value.token_type
          expire_in_seconds = authentication.value.expire_in_seconds
          refresh_token     = authentication.value.refresh_token
          scope             = authentication.value.scope
        }
      }
    }
  }
  dynamic "timeouts" {
    for_each = var.task.timeouts == null ? [] : [var.task.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
  dynamic "timer_trigger" {
    for_each = var.task.timer_triggers

    content {
      name     = timer_trigger.value.name
      schedule = timer_trigger.value.schedule
      enabled  = timer_trigger.value.enabled
    }
  }

  lifecycle {
    precondition {
      condition     = var.task.is_system_task ? var.task.name == "quicktask" : true
      error_message = "For a system task, the task name must be set to `quicktask`."
    }
    precondition {
      condition     = var.task.is_system_task ? var.task.platform == null : true
      error_message = "For a system task, `platform` cannot be specified."
    }
    precondition {
      condition     = var.task.is_system_task ? var.task.docker_step == null && var.task.encoded_step == null && var.task.file_step == null : true
      error_message = "For a system task, `docker_step`, `encoded_step`, and `file_step` cannot be specified."
    }
    precondition {
      condition     = var.task.is_system_task ? var.task.base_image_trigger == null && length(var.task.source_triggers) == 0 && length(var.task.timer_triggers) == 0 : true
      error_message = "For a system task, `base_image_trigger`, `source_triggers`, and `timer_triggers` cannot be specified."
    }
    precondition {
      condition     = var.task.is_system_task ? true : var.task.platform != null
      error_message = "For a non-system task, `platform` is required."
    }
    precondition {
      condition = var.task.is_system_task ? true : length(compact([
        var.task.docker_step == null ? "" : "docker",
        var.task.encoded_step == null ? "" : "encoded",
        var.task.file_step == null ? "" : "file"
      ])) == 1
      error_message = "For a non-system task, exactly one of `docker_step`, `encoded_step`, or `file_step` must be specified."
    }
  }
}

resource "azurerm_container_registry_task_schedule_run_now" "this" {
  for_each = try(var.task.schedule_run_now.enabled, false) ? { this = var.task.schedule_run_now } : {}

  container_registry_task_id = azurerm_container_registry_task.this.id

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
    }
  }
}
