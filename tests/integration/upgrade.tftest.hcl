# Upgrade test (SNFR5). Deploys the last AzureRM-based release, then applies the local module to the same state.
# The registry's creation date must not change. A changed date means Terraform deleted and recreated the registry.
# Keep the published version pinned to the last AzureRM-based release for the whole AzAPI migration compatibility window.

provider "azapi" {}

# The published release still manages AzureRM resources, so its half of this test needs a configured AzureRM provider.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

run "setup" {
  module {
    source = "./tests/integration/fixtures/setup"
  }

  variables {
    location = "australiaeast"
  }
}

run "deploy_published_release" {
  state_key = "registry"

  module {
    source  = "Azure/avm-res-containerregistry-registry/azurerm"
    version = "0.9.0"
  }

  variables {
    enable_telemetry    = false
    location            = run.setup.location
    name                = "acrupg${run.setup.suffix}"
    resource_group_name = run.setup.resource_group_name
  }
}

run "read_published_registry" {
  module {
    source = "./tests/integration/fixtures/registry"
  }

  variables {
    resource_id = run.deploy_published_release.resource_id
  }

  assert {
    condition     = try(length(output.creation_date) > 0, false)
    error_message = "Azure did not return a creation date for the registry, so the upgrade comparison would prove nothing."
  }
}

run "upgrade_to_local_module" {
  state_key = "registry"

  variables {
    enable_telemetry    = false
    location            = run.setup.location
    name                = "acrupg${run.setup.suffix}"
    resource_group_name = run.setup.resource_group_name
  }

  assert {
    condition     = output.resource_id == run.deploy_published_release.resource_id
    error_message = "The upgraded module manages a different registry than the published release deployed."
  }
}

run "read_upgraded_registry" {
  module {
    source = "./tests/integration/fixtures/registry"
  }

  variables {
    resource_id = run.upgrade_to_local_module.resource_id
  }

  assert {
    condition     = output.creation_date == run.read_published_registry.creation_date
    error_message = "The upgrade replaced the registry. Its creation date changed from ${run.read_published_registry.creation_date} to ${output.creation_date}."
  }
}
