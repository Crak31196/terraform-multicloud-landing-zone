output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "URI used by applications/SDKs to reach the vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "purge_protection_enabled" {
  description = "Whether purge protection is enabled on the vault."
  value       = azurerm_key_vault.this.purge_protection_enabled
}
