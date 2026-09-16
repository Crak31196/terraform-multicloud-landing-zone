output "waf_policy_id" {
  description = "Resource ID of the WAF policy. Pass to an Application Gateway's firewall_policy_id."
  value       = azurerm_web_application_firewall_policy.this.id
}

output "waf_policy_name" {
  description = "Name of the WAF policy."
  value       = azurerm_web_application_firewall_policy.this.name
}

output "mode" {
  description = "Configured WAF mode (Prevention or Detection)."
  value       = azurerm_web_application_firewall_policy.this.policy_settings[0].mode
}
