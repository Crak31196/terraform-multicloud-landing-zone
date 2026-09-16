# Integration-style native test for the Azure landing zone example: proves the root
# module wiring (vnet + keyvault + waf + rbac-baseline) plans cleanly end to end
# against a mocked provider, with no real Azure credentials required.
#
# Run with: (from examples/azure-landing-zone) terraform test

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "11111111-1111-1111-1111-111111111111"
      object_id       = "22222222-2222-2222-2222-222222222222"
    }
  }
}

variables {
  name_prefix = "acme"
  environment = "dev"
  location    = "eastus"

  address_space = ["10.1.0.0/16"]
  subnets = {
    app = { address_prefixes = ["10.1.1.0/24"] }
    db  = { address_prefixes = ["10.1.2.0/24"] }
  }

  rbac_admin_object_ids = ["22222222-2222-2222-2222-222222222222"]
  role_assignments = [
    {
      principal_id         = "22222222-2222-2222-2222-222222222222"
      role_definition_name = "Reader"
    }
  ]
}

run "landing_zone_plans_cleanly" {
  # Provider-computed IDs stay unknown at plan time, so this only asserts on values
  # known from configuration -- module internals are covered by each module's tests.
  command = plan

  assert {
    condition     = length(output.subnet_ids) == 2
    error_message = "The example should wire through 2 subnets (app, db)."
  }

  assert {
    condition     = output.resource_group_name == "acme-dev-rg"
    error_message = "The resource group name should follow the <name_prefix>-<environment>-rg convention."
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
