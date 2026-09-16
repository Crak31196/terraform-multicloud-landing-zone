# Native Terraform tests for the Azure VNet module, run entirely against a mocked
# provider -- no Azure credentials or network access required.
#
# Run with: (from modules/azure/vnet) terraform test

mock_provider "azurerm" {}

variables {
  name_prefix         = "acme"
  environment         = "dev"
  location            = "eastus"
  resource_group_name = "acme-dev-rg"
  address_space       = ["10.1.0.0/16"]
  subnets = {
    app = { address_prefixes = ["10.1.1.0/24"] }
    db  = { address_prefixes = ["10.1.2.0/24"] }
  }
}

run "creates_one_subnet_and_nsg_per_entry" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this) == 2
    error_message = "Expected one subnet per entry in var.subnets."
  }

  assert {
    condition     = length(azurerm_network_security_group.this) == 2
    error_message = "Expected one Network Security Group per subnet."
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == 2
    error_message = "Every subnet should have its NSG associated."
  }
}

run "default_nsg_rule_denies_inbound_internet" {
  command = plan

  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.this["app"].security_rule :
      r.access == "Deny" && r.source_address_prefix == "Internet"
    ])
    error_message = "The baseline NSG should include a rule that denies inbound traffic from the Internet service tag."
  }
}

run "vnet_uses_supplied_address_space" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this.address_space[0] == "10.1.0.0/16"
    error_message = "The VNet should use the supplied address_space."
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}

run "rejects_invalid_address_space" {
  command = plan

  variables {
    address_space = ["not-a-cidr"]
  }

  expect_failures = [var.address_space]
}

run "rejects_empty_subnets" {
  command = plan

  variables {
    subnets = {}
  }

  expect_failures = [var.subnets]
}
