# Cache rules

This example deploys a Premium Container Registry with three cache rules:

- **`dockerhub_nginx`** — an authenticated cache rule that mirrors `docker.io/library/nginx` from Docker Hub.
- **`dockerhub_alpine`** — an authenticated cache rule that mirrors `docker.io/library/alpine` and reuses the same registry-level Docker Hub credential set as the nginx rule. The shared credential set's system-assigned managed identity receives exactly one **Key Vault Secrets User** role assignment.
- **`mcr_hello_world`** — an unauthenticated cache rule that mirrors `mcr.microsoft.com/mcr/hello-world` from Microsoft Container Registry (public, no credential set required).

> [!NOTE]
> The Docker Hub username and password are placeholders, so Azure reports the credential set as unhealthy and no Docker Hub image can actually be pulled. This example verifies the resource wiring rather than a live upstream pull. Replace the placeholders with real credentials for production use. Granting the credential set identity access to the Key Vault is the caller's responsibility and is demonstrated here with one role assignment against the shared credential set's discrete `principal_id` output.
