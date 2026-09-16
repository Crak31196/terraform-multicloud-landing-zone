variable "name_prefix" {
  description = "Short prefix used to name the WAF policy (e.g. \"acme-prod\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1-32 lowercase alphanumeric characters/hyphens and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment. Drives the environment tag and part of the policy name."
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
  description = "Name of an existing resource group to deploy the WAF policy into."
  type        = string
}

variable "mode" {
  description = "WAF mode: \"Prevention\" blocks matched requests, \"Detection\" only logs them."
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Prevention", "Detection"], var.mode)
    error_message = "mode must be \"Prevention\" or \"Detection\"."
  }
}

variable "managed_rule_set_type" {
  description = "Managed rule set type, e.g. \"OWASP\" or \"Microsoft_DefaultRuleSet\"."
  type        = string
  default     = "OWASP"
}

variable "managed_rule_set_version" {
  description = "Managed rule set version, e.g. \"3.2\" for OWASP."
  type        = string
  default     = "3.2"
}

variable "file_upload_limit_mb" {
  description = "Maximum file upload size (MB) permitted through the WAF."
  type        = number
  default     = 100

  validation {
    condition     = var.file_upload_limit_mb > 0 && var.file_upload_limit_mb <= 4000
    error_message = "file_upload_limit_mb must be between 1 and 4000."
  }
}

variable "tags" {
  description = "Additional tags merged onto the WAF policy."
  type        = map(string)
  default     = {}
}
