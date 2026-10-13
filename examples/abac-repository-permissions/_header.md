# ABAC repository permissions example

This example sets `role_assignment_mode` to `AbacRepositoryPermissions`.

It also sets `azuread_authentication_as_arm_policy_enabled` to `false`, so the registry accepts only registry-scoped Microsoft Entra tokens. Azure Landing Zones guardrails enforce this setting through Azure Policy.
