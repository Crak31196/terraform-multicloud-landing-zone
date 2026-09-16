output "role_assignment_ids" {
  description = "IDs of the baseline RBAC role assignments created."
  value       = [for ra in azurerm_role_assignment.baseline : ra.id]
}

output "require_tags_policy_assignment_id" {
  description = "ID of the require-tags policy assignment."
  value       = azurerm_resource_group_policy_assignment.require_tags.id
}

output "deny_public_ip_policy_assignment_id" {
  description = "ID of the deny-public-IP policy assignment (null if disabled)."
  value       = var.deny_public_ip ? azurerm_resource_group_policy_assignment.deny_public_ip[0].id : null
}
