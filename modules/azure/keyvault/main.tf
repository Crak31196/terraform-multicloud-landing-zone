# Azure Key Vault baseline for secrets/keys management: RBAC authorization by
# default, soft-delete + purge protection enabled, and a default-deny network ACL.

locals {
  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "azurerm_key_vault" "this" {
  name                = "${var.name_prefix}-${var.environment}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  enable_rbac_authorization  = var.enable_rbac_authorization
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  network_acls {
    default_action = var.network_default_action
    bypass         = "AzureServices"
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "kv_admins" {
  for_each             = var.enable_rbac_authorization ? toset(var.rbac_admin_object_ids) : []
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_key_vault_access_policy" "this" {
  for_each     = var.enable_rbac_authorization ? {} : { for p in var.access_policies : p.object_id => p }
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = each.value.object_id

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
}
