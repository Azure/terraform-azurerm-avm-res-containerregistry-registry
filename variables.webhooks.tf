variable "webhooks" {
  type = map(object({
    actions        = set(string)
    custom_headers = optional(map(string))
    name           = string
    scope          = optional(string)
    service_uri    = string
    status         = optional(string)
    tags           = optional(map(string))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  description = <<-EOT
A map of webhooks to be added to the Container Registry.

- `actions` - (Required) A list of actions that trigger the Webhook to post notifications. At least one action needs to be specified. Valid values are: `push`, `delete`, `quarantine`, `chart_push`, `chart_delete`
- `custom_headers` - (Optional) Custom headers that will be added to the webhook notifications request.
- `name` - (Required) Specifies the name of the Container Registry Webhook. Only Alphanumeric characters allowed. Changing this forces a new resource to be created.
- `scope` - (Optional) Specifies the scope of repositories that can trigger an event. For example, `foo:*` means events for all tags under repository `foo`. `foo:bar` means events for 'foo:bar' only. `foo` is equivalent to `foo:latest`. Empty means all events. Defaults to `""`.
- `service_uri` - (Required) Specifies the service URI for the Webhook to post notifications.
- `status` - (Optional) Specifies if this Webhook triggers notifications or not. Valid values: `enabled` and `disabled`. Default is `enabled`.
- `tags` - (Optional) A mapping of tags to assign to the resource.

---
`timeouts` block supports the following:

- `create` - (Defaults to 30 minutes) Used when creating the Container Registry Webhook.
- `delete` - (Defaults to 30 minutes) Used when deleting the Container Registry Webhook.
- `read` - (Defaults to 5 minutes) Used when retrieving the Container Registry Webhook.
- `update` - (Defaults to 30 minutes) Used when updating the Container Registry Webhook.

EOT
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for webhook, config in var.webhooks : (
        length(regex("^[a-zA-Z0-9]+$", config.name)) > 0 &&
        length(config.name) >= 5 &&
        length(config.name) <= 50
      )
    ])

    error_message = "Name for webhook must be alphanumeric and between 5 and 50 characters."
  }
}
