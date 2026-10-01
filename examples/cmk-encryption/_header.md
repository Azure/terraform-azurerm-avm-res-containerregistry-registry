# Customer managed key encryption

This deploys the Container Registry module with customer-managed-key encryption.

The Key Vault, the key, the user assigned identity and the registry are all created by a single `terraform apply`. That works because `customer_managed_key` takes the values the Container Registry API actually consumes -- the full key URI and the identity's client ID -- and the example builds both from the resources it owns:

```hcl
customer_managed_key = {
  key_vault_key_uri = azurerm_key_vault_key.key.versionless_id
  user_assigned_identity = {
    client_id = azurerm_user_assigned_identity.this.client_id
  }
}
```

Both values are unknown until apply, so Terraform orders the registry after the key and the identity. Passing a hard-coded key name instead would leave the registry with no reason to wait for the key.

The URI is versionless, so the registry follows key rotations automatically. Append a version segment to pin to a specific key version.

The same identity must also be assigned to the registry through `managed_identities.user_assigned_resource_ids`.
