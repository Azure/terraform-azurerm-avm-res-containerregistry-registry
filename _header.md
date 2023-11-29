# terraform-azurerm-avm-containerregistry

This is a Container Registry repo in the style of Azure Verified Modules (AVM), it is an 'unofficial' example that has been used for learning AVM.

As a starting point, the azurerm_container_registry resource has been implemented, noting this supports all attributes such as georeplication and zone redundancy.

In additional, private endpoints, locks and role assignments have been done in the style of AVM (I hope 😊).

An end to end test runs with each CI, this does an end to end deployment into Azure, along with resource tidy up.  This runs for the default parameters (more elaborate ones TODO!)

There is currently an upstream issue with linting which has been raised.

To find official modules, please visit: <https://aka.ms/akm>.

Things to do:

1. Set up a GitHub repo environment called `test`.
1. Configure environment protection rule to ensure that approval is required before deploying to this environment.
1. Create a user-assigned managed identity in your test subscription.
1. Create a role assignment for the managed identity on your test subscription, use the minimum required role.
1. Configure federated identity credentials on the user assigned managed identity. Use the GitHub environment.
1. Create the following environment secrets on the `test` environment:
   1. AZURE_CLIENT_ID
   1. AZURE_TENANT_ID
   1. AZURE_SUBSCRIPTION_ID
