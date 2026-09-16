# Azure governance baseline: baseline RBAC role assignments plus custom Azure Policy
# definitions/assignments for "require tags" and "deny public IP" -- the Azure-side
# equivalent of the AWS Config governance rules in modules/aws/iam-baseline.

locals {
  policy_parameters = {
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy."
      }
      allowedValues = ["Deny", "Audit", "Disabled"]
      defaultValue  = var.policy_effect
    }
  }
}

resource "azurerm_role_assignment" "baseline" {
  for_each             = { for ra in var.role_assignments : "${ra.principal_id}-${ra.role_definition_name}" => ra }
  scope                = var.policy_assignment_scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# --- Require-tags policy ------------------------------------------------------

resource "azurerm_policy_definition" "require_tags" {
  name         = "${var.name_prefix}-${var.environment}-require-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require tags: ${join(", ", var.required_tag_keys)} (${var.name_prefix}-${var.environment})"
  description  = "Denies (or audits) resource creation/update when any of the required tags is missing."

  parameters = jsonencode(local.policy_parameters)

  policy_rule = jsonencode({
    if = {
      anyOf = [
        for key in var.required_tag_keys : {
          field  = "tags['${key}']"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_tags" {
  name                 = "${var.name_prefix}-${var.environment}-require-tags"
  display_name         = "Require tags (${var.environment})"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  resource_group_id    = var.policy_assignment_scope

  parameters = jsonencode({
    effect = { value = var.policy_effect }
  })
}

# --- Deny-public-IP policy -----------------------------------------------------

resource "azurerm_policy_definition" "deny_public_ip" {
  count        = var.deny_public_ip ? 1 : 0
  name         = "${var.name_prefix}-${var.environment}-deny-public-ip"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Deny public IP addresses (${var.name_prefix}-${var.environment})"
  description  = "Denies (or audits) creation of Microsoft.Network/publicIPAddresses resources -- startups rarely need them by default, and each one is an internet-facing attack surface to track."

  parameters = jsonencode(local.policy_parameters)

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Network/publicIPAddresses"
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "deny_public_ip" {
  count                = var.deny_public_ip ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-deny-public-ip"
  display_name         = "Deny public IPs (${var.environment})"
  policy_definition_id = azurerm_policy_definition.deny_public_ip[0].id
  resource_group_id    = var.policy_assignment_scope

  parameters = jsonencode({
    effect = { value = var.policy_effect }
  })
}
