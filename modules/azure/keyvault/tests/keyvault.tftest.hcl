# Native Terraform tests for the Azure Key Vault module, run entirely against a
# mocked provider -- no Azure credentials or network access required.
#
# Run with: (from modules/azure/keyvault) terraform test

mock_provider "azurerm" {}

variables {
  name_prefix         = "acme"
  environment         = "dev"
  location            = "eastus"
  resource_group_name = "acme-dev-rg"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.enable_rbac_authorization == true
    error_message = "enable_rbac_authorization should default to true."
  }

  assert {
    condition     = azurerm_key_vault.this.purge_protection_enabled == true
    error_message = "purge_protection_enabled should default to true."
  }

  assert {
    condition     = azurerm_key_vault.this.soft_delete_retention_days == 90
    error_message = "soft_delete_retention_days should default to 90."
  }

  assert {
    condition     = azurerm_key_vault.this.network_acls[0].default_action == "Deny"
    error_message = "network_default_action should default to Deny (secure by default)."
  }
}

run "vault_name_follows_convention" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.name == "acme-dev-kv"
    error_message = "Vault name should follow the <name_prefix>-<environment>-kv convention."
  }
}

run "no_access_policies_when_rbac_enabled" {
  command = plan

  variables {
    access_policies = [
      {
        object_id          = "11111111-1111-1111-1111-111111111111"
        secret_permissions = ["Get"]
      }
    ]
  }

  assert {
    condition     = length(azurerm_key_vault_access_policy.this) == 0
    error_message = "Access policies should not be created while RBAC authorization is enabled."
  }
}

run "access_policies_created_when_rbac_disabled" {
  command = plan

  variables {
    enable_rbac_authorization = false
    access_policies = [
      {
        object_id          = "11111111-1111-1111-1111-111111111111"
        secret_permissions = ["Get"]
      }
    ]
  }

  assert {
    condition     = length(azurerm_key_vault_access_policy.this) == 1
    error_message = "Exactly one access policy should be created when RBAC is disabled and one policy is supplied."
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}

run "rejects_invalid_sku" {
  command = plan

  variables {
    sku_name = "enterprise"
  }

  expect_failures = [var.sku_name]
}

run "rejects_soft_delete_retention_out_of_range" {
  command = plan

  variables {
    soft_delete_retention_days = 400
  }

  expect_failures = [var.soft_delete_retention_days]
}
