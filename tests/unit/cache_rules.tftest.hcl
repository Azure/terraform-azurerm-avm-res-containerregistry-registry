mock_provider "azapi" {}
mock_provider "azurerm" {
  mock_resource "azurerm_container_registry" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/acrtest"
      name = "acrtest"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry    = false
  location            = "eastus"
  name                = "acrtest"
  resource_group_name = "rg-test"
}

run "cache_rule_without_credential_set" {
  command   = apply
  state_key = "cache-rule-without-credential-set"

  variables {
    cache_rules = {
      mcr_hello_world = {
        name              = "mcr-hello-world"
        source_repository = "mcr.microsoft.com/mcr/hello-world"
        target_repository = "hello-world"
      }
    }
  }

  assert {
    condition     = length(module.cache_rule) == 1
    error_message = "Exactly one cache rule submodule instance should be created."
  }

  assert {
    condition     = length(module.credential_set) == 0
    error_message = "No credential set should be created for a cache rule without a credential_set."
  }

  assert {
    condition     = length(output.credential_sets) == 0
    error_message = "The credential_sets output should be empty when no credential sets are configured."
  }

  assert {
    condition     = output.cache_rules["mcr_hello_world"].name == "mcr-hello-world"
    error_message = "The cache_rules output should expose the configured cache rule name."
  }

  assert {
    condition     = module.cache_rule["mcr_hello_world"].name == "mcr-hello-world"
    error_message = "The cache rule submodule should be named after the configured cache rule."
  }
}

run "cache_rule_with_credential_set" {
  command   = apply
  state_key = "cache-rule-with-credential-set"

  variables {
    cache_rules = {
      dockerhub_nginx = {
        name              = "dockerhub-nginx"
        source_repository = "docker.io/library/nginx"
        target_repository = "nginx"
        credential_set = {
          name         = "dockerhub-credentials"
          login_server = "docker.io"
          auth_credentials = [
            {
              username_secret_identifier = "https://kv-test.vault.azure.net/secrets/docker-username"
              password_secret_identifier = "https://kv-test.vault.azure.net/secrets/docker-password"
            }
          ]
        }
      }
    }
  }

  assert {
    condition     = length(module.cache_rule) == 1
    error_message = "Exactly one cache rule submodule instance should be created."
  }

  assert {
    condition     = length(module.credential_set) == 1
    error_message = "A credential set should be created for a cache rule that configures one."
  }

  assert {
    condition     = length(output.credential_sets) == 1
    error_message = "The credential_sets output should expose the created credential set."
  }

  assert {
    condition     = contains(keys(output.credential_sets), "dockerhub_nginx")
    error_message = "The credential_sets output should be keyed by the cache rule key."
  }

  assert {
    condition     = module.credential_set["dockerhub_nginx"].name == "dockerhub-credentials"
    error_message = "The credential set submodule should be named after the configured credential set."
  }
}

run "mixed_cache_rules_cardinality" {
  command   = apply
  state_key = "mixed-cache-rules-cardinality"

  variables {
    cache_rules = {
      dockerhub_nginx = {
        name              = "dockerhub-nginx"
        source_repository = "docker.io/library/nginx"
        target_repository = "nginx"
        credential_set = {
          name         = "dockerhub-credentials"
          login_server = "docker.io"
          auth_credentials = [
            {
              username_secret_identifier = "https://kv-test.vault.azure.net/secrets/docker-username"
              password_secret_identifier = "https://kv-test.vault.azure.net/secrets/docker-password"
            }
          ]
        }
      }
      mcr_hello_world = {
        name              = "mcr-hello-world"
        source_repository = "mcr.microsoft.com/mcr/hello-world"
        target_repository = "hello-world"
      }
    }
  }

  assert {
    condition     = length(module.cache_rule) == 2
    error_message = "One cache rule submodule instance should be created per cache_rules entry."
  }

  assert {
    condition     = length(module.credential_set) == 1
    error_message = "Only cache rules with a credential_set should create a credential set."
  }
}

run "cache_rules_require_premium_sku" {
  command   = plan
  state_key = "cache-rules-require-premium-sku"

  variables {
    sku = "Basic"
    cache_rules = {
      mcr_hello_world = {
        name              = "mcr-hello-world"
        source_repository = "mcr.microsoft.com/mcr/hello-world"
        target_repository = "hello-world"
      }
    }
  }

  expect_failures = [
    azurerm_container_registry.this,
  ]
}
