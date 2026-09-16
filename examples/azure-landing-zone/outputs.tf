output "resource_group_name" {
  description = "Name of the landing zone resource group."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "ID of the landing zone virtual network."
  value       = module.vnet.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name => subnet ID."
  value       = module.vnet.subnet_ids
}

output "key_vault_uri" {
  description = "URI of the landing zone Key Vault."
  value       = module.keyvault.vault_uri
}

output "waf_policy_id" {
  description = "ID of the WAF policy (attach to an Application Gateway's firewall_policy_id)."
  value       = module.waf.waf_policy_id
}

output "require_tags_policy_assignment_id" {
  description = "ID of the require-tags governance policy assignment."
  value       = module.rbac_baseline.require_tags_policy_assignment_id
}
