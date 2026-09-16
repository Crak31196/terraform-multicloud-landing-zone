variable "name_prefix" {
  description = "Short prefix used to name the vault. Azure Key Vault names must be globally unique, 3-24 chars."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,20}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1-22 lowercase alphanumeric characters/hyphens and cannot start or end with a hyphen (the vault name adds an environment suffix)."
  }
}

variable "environment" {
  description = "Deployment environment. Drives the environment tag and part of the vault name."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region, e.g. eastus."
  type        = string
}

variable "resource_group_name" {
  description = "Name of an existing resource group to deploy the vault into."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID that owns the vault (typically data.azurerm_client_config.current.tenant_id)."
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be either \"standard\" or \"premium\"."
  }
}

variable "enable_rbac_authorization" {
  description = "Use Azure RBAC for data-plane authorization instead of vault access policies. Recommended default for a secure baseline."
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Prevent permanent deletion of the vault (and its secrets/keys) during the soft-delete retention window. Should stay true for any vault holding real secrets."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days deleted vault items are recoverable before permanent purge."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "rbac_admin_object_ids" {
  description = "Azure AD object IDs granted the \"Key Vault Administrator\" role when enable_rbac_authorization is true."
  type        = list(string)
  default     = []
}

variable "access_policies" {
  description = <<-EOT
    Used only when enable_rbac_authorization is false. List of legacy access-policy
    grants: { object_id, key_permissions, secret_permissions, certificate_permissions }.
  EOT
  type = list(object({
    object_id               = string
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
  }))
  default = []
}

variable "network_default_action" {
  description = "Default network ACL action for the vault firewall: Allow or Deny. Deny is the secure-by-default choice; add explicit allow rules for known client networks."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "network_default_action must be \"Allow\" or \"Deny\"."
  }
}

variable "tags" {
  description = "Additional tags merged onto the vault."
  type        = map(string)
  default     = {}
}
