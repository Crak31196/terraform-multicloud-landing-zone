variable "name_prefix" {
  description = "Short prefix used to name the key alias (e.g. \"acme-prod\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1-32 lowercase alphanumeric characters/hyphens and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment. Drives the Environment tag and alias suffix."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "key_usage_description" {
  description = "Human-readable description of what this key encrypts (e.g. \"RDS at-rest encryption\")."
  type        = string
  default     = "General-purpose encryption-at-rest key for the landing zone."
}

variable "key_administrators" {
  description = "List of IAM ARNs allowed to administer (but not necessarily use) the key."
  type        = list(string)

  validation {
    condition     = length(var.key_administrators) > 0
    error_message = "At least one key administrator ARN must be supplied so the key is never left unmanageable."
  }
}

variable "key_users" {
  description = "List of IAM ARNs allowed to use the key for encrypt/decrypt operations."
  type        = list(string)
  default     = []
}

variable "deletion_window_in_days" {
  description = "Waiting period before the key is deleted after a destroy request."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "enable_key_rotation" {
  description = "Whether automatic annual key rotation is enabled. Should stay true for any production key."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags merged onto the key and alias."
  type        = map(string)
  default     = {}
}
