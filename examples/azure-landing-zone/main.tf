# Example root module wiring the Azure baseline modules together into one landing zone.
# This is a starting point to copy into a client's own repo, not a shared multi-tenant
# stack -- each client/environment gets its own state.

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source = "../../modules/azure/vnet"

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.address_space
  subnets             = var.subnets
  tags                = var.tags
}

module "keyvault" {
  source = "../../modules/azure/keyvault"

  name_prefix           = var.name_prefix
  environment           = var.environment
  location              = var.location
  resource_group_name   = azurerm_resource_group.this.name
  tenant_id             = data.azurerm_client_config.current.tenant_id
  rbac_admin_object_ids = var.rbac_admin_object_ids
  tags                  = var.tags
}

module "waf" {
  source = "../../modules/azure/waf"

  name_prefix         = var.name_prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

module "rbac_baseline" {
  source = "../../modules/azure/rbac-baseline"

  name_prefix             = var.name_prefix
  environment             = var.environment
  policy_assignment_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.this.name}"
  role_assignments        = var.role_assignments
  required_tag_keys       = var.required_tag_keys
  policy_effect           = var.policy_effect
}
