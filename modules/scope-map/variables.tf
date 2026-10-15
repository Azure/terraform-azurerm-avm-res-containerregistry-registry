variable "actions" {
  type        = list(string)
  description = "List of actions to attach to the scope map."
  nullable    = false
}

variable "container_registry_name" {
  type        = string
  description = "The name of the Container Registry."
  nullable    = false
}

variable "description" {
  type        = string
  description = "The description of the Container Registry."
}

variable "location" {
  type        = string
  description = "The Azure region for this module's resources or telemetry deployment."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the scope map."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Container Registry scope and token(if variable registry_tokens is defined)."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "registry_tokens" {
  type = map(object({
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
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Container Registry token associated to a scope map. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - Specifies the name of the token.
- `enabled` - Should the Container Registry token be enabled? Defaults to true."
DESCRIPTION
  nullable    = false
}
