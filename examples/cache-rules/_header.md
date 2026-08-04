# Cache rules

This example deploys a Premium Container Registry with two cache rules:

- **`dockerhub_nginx`** — an authenticated cache rule that mirrors `docker.io/library/nginx` from Docker Hub. Because Docker Hub is rate-limited, it uses a **credential set** backed by Key Vault secrets. The credential set's system-assigned managed identity is granted the **Key Vault Secrets User** role so it can read those secrets.
- **`mcr_hello_world`** — an unauthenticated cache rule that mirrors `mcr.microsoft.com/mcr/hello-world` from Microsoft Container Registry (public, no credential set required).

> [!NOTE]
> The Docker Hub username and password are placeholder values. Replace them with real credentials to actually authenticate against Docker Hub. Granting the credential set identity access to the Key Vault is the caller's responsibility and is demonstrated here with a role assignment against the discrete `principal_id` output.
