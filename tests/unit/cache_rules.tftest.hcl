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
    error_message = "No credential set should be created when credential_sets is empty."
  }

  assert {
    condition     = length(output.credential_sets) == 0
    error_message = "The credential_sets output should be empty when no credential sets are configured."
  }

  assert {
    condition     = output.cache_rules["mcr_hello_world"].name == "mcr-hello-world"
    error_message = "The cache_rules output should expose the configured cache rule name."
  }
}

run "two_cache_rules_share_one_credential_set" {
  command   = apply
  state_key = "two-cache-rules-share-one-credential-set"

  variables {
    credential_sets = {
      dockerhub = {
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
    cache_rules = {
      dockerhub_nginx = {
        name               = "dockerhub-nginx"
        source_repository  = "docker.io/library/nginx"
        target_repository  = "nginx"
        credential_set_key = "dockerhub"
      }
      dockerhub_alpine = {
        name               = "dockerhub-alpine"
        source_repository  = "docker.io/library/alpine"
        target_repository  = "alpine"
        credential_set_key = "dockerhub"
      }
    }
  }

  assert {
    condition     = length(module.cache_rule) == 2
    error_message = "Two cache rule submodule instances should be created."
  }

  assert {
    condition     = length(module.credential_set) == 1
    error_message = "Two cache rules sharing one credential_set_key should create exactly one credential set."
  }

  assert {
    condition     = contains(keys(output.credential_sets), "dockerhub")
    error_message = "The credential_sets output should be keyed by the caller-supplied credential set key."
  }

  assert {
    condition     = module.credential_set["dockerhub"].name == "dockerhub-credentials"
    error_message = "The credential set submodule should use the configured credential set name."
  }
}

run "bring_your_own_credential_set" {
  command   = apply
  state_key = "bring-your-own-credential-set"

  variables {
    cache_rules = {
      external = {
        name                       = "external-credentials"
        source_repository          = "docker.example.com/team/app"
        target_repository          = "team/app"
        credential_set_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/acrtest/credentialSets/external-credentials"
      }
    }
  }

  assert {
    condition     = length(module.cache_rule) == 1
    error_message = "A cache rule should be created for a bring-your-own credential set resource ID."
  }

  assert {
    condition     = length(module.credential_set) == 0
    error_message = "A bring-your-own credential_set_resource_id must not create a module-managed credential set."
  }
}

run "duplicate_credential_set_names" {
  command   = plan
  state_key = "duplicate-credential-set-names"

  variables {
    credential_sets = {
      primary = {
        name         = "dockerhub-credentials"
        login_server = "docker.io"
        auth_credentials = [{
          username_secret_identifier = "https://kv-test.vault.azure.net/secrets/username"
          password_secret_identifier = "https://kv-test.vault.azure.net/secrets/password"
        }]
      }
      secondary = {
        name         = "DockerHub-Credentials"
        login_server = "docker.io"
        auth_credentials = [{
          username_secret_identifier = "https://kv-test.vault.azure.net/secrets/username"
          password_secret_identifier = "https://kv-test.vault.azure.net/secrets/password"
        }]
      }
    }
  }

  expect_failures = [var.credential_sets]
}

run "credential_set_references_are_mutually_exclusive" {
  command   = plan
  state_key = "credential-set-references-are-mutually-exclusive"

  variables {
    credential_sets = {
      dockerhub = {
        name         = "dockerhub-credentials"
        login_server = "docker.io"
        auth_credentials = [{
          username_secret_identifier = "https://kv-test.vault.azure.net/secrets/username"
          password_secret_identifier = "https://kv-test.vault.azure.net/secrets/password"
        }]
      }
    }
    cache_rules = {
      invalid = {
        name                       = "invalid-credentials"
        source_repository          = "docker.io/library/nginx"
        target_repository          = "nginx"
        credential_set_key         = "dockerhub"
        credential_set_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/acrtest/credentialSets/external-credentials"
      }
    }
  }

  expect_failures = [var.cache_rules]
}

run "credential_set_key_must_exist" {
  command   = plan
  state_key = "credential-set-key-must-exist"

  variables {
    cache_rules = {
      missing = {
        name               = "missing-credentials"
        source_repository  = "docker.io/library/nginx"
        target_repository  = "nginx"
        credential_set_key = "not-defined"
      }
    }
  }

  expect_failures = [azurerm_container_registry.this]
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

  expect_failures = [azurerm_container_registry.this]
}

run "credential_sets_require_premium_sku" {
  command   = plan
  state_key = "credential-sets-require-premium-sku"

  variables {
    sku = "Basic"
    credential_sets = {
      dockerhub = {
        name         = "dockerhub-credentials"
        login_server = "docker.io"
        auth_credentials = [{
          username_secret_identifier = "https://kv-test.vault.azure.net/secrets/username"
          password_secret_identifier = "https://kv-test.vault.azure.net/secrets/password"
        }]
      }
    }
  }

  expect_failures = [azurerm_container_registry.this]
}
