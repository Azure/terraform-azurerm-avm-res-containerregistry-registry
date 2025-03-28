variable "name" {
  type        = string
  description = "The name of the scope map."
  nullable    = false
}

variable "container_registry_name" {
  type        = string
  description = "The name of the Container Registry."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Container Registry token."
  nullable    = false
}

variable "actions" {
  type        = list(string)
  description = "List of actions to attach to the scope map."
  nullable    = false
}

variable "description" {
  type        = string
  description = "The description of the Container Registry."
  nullable    = true
}