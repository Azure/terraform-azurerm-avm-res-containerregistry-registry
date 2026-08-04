# terraform-azurerm-avm-res-containerregistry-registry//credential-set

Submodule to deploy a Container Registry credential set (`Microsoft.ContainerRegistry/registries/credentialSets`).

A credential set stores a reference to Key Vault secrets (username / password) that Azure Container Registry uses to authenticate to an upstream registry (for example Docker Hub) when a cache rule pulls images. It is provisioned with a system-assigned managed identity whose principal must be granted read access (for example the **Key Vault Secrets User** role) to the Key Vault holding those secrets.

Granting Key Vault access to the credential set's system-assigned identity is the **caller's responsibility** — this submodule only exports the `principal_id` so the caller can create the role assignment.
