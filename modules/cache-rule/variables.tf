variable "container_registry_id" {
  type        = string
  description = "The ID of the Container Registry."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the cache rule."
  nullable    = false
}

variable "source_repository" {
  type        = string
  description = "The source repository path to cache from (e.g., 'library/hello-world' for Docker Hub)."
  nullable    = false
}

variable "target_repository" {
  type        = string
  description = "The target repository path in your registry where the cached image will be stored."
  nullable    = false
}

variable "credential_set" {
  type = object({
    name               = string
    login_server       = string
    username_secret_id = string
    password_secret_id = string
  })
  default     = null
  description = <<DESCRIPTION
Optional credential set configuration for authenticated pulls from the source registry.
If provided, a credential set will be created and automatically associated with this cache rule.
Required for Docker Hub due to rate limits. Not required for public registries like MCR.

- `name` - (Required) The name of the credential set.
- `login_server` - (Required) The external registry login server (e.g., 'docker.io' for Docker Hub).
- `username_secret_id` - (Required) The Key Vault secret ID containing the username.
- `password_secret_id` - (Required) The Key Vault secret ID containing the password.

Note: The system-assigned identity of the credential set will need 'Key Vault Secrets User' role on the Key Vault.
DESCRIPTION
}
