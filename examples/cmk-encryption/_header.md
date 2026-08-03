# Default example

This deploys the Container Registry module with customer-managed-key encryption.

The Key Vault Key and User Assigned Identity are created in the same `terraform apply` as the Container Registry.
The example supplies their computed values through `customer_managed_key.direct_values`, which prevents the module
from reading those resources back through data sources before they exist.
