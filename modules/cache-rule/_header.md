# terraform-azurerm-avm-res-containerregistry-registry//cache-rule

Submodule to deploy a Container Registry cache rule (`Microsoft.ContainerRegistry/registries/cacheRules`).

A cache rule maps a source repository in an upstream public registry (for example `docker.io/library/nginx` on Docker Hub or `mcr.microsoft.com/mcr/hello-world` on Microsoft Container Registry) to a target repository in the Container Registry, so pulls are cached locally for faster and more reliable access.

Cache rules that pull from a rate-limited or authenticated upstream (such as Docker Hub) reference a **credential set** via `credential_set_resource_id`. Deploy a shareable registry-level credential set with the sibling `credential-set` submodule and pass its `resource_id`, or supply the ID of an existing credential set. Public upstreams like Microsoft Container Registry (MCR) do not require a credential set.
