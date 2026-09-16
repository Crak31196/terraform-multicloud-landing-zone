variable "name_prefix" {
  description = "Short prefix used to name every resource created by this module (e.g. \"acme-prod\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1-32 lowercase alphanumeric characters/hyphens and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment. Drives the Environment tag applied to every resource."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "break_glass_principal_arns" {
  description = <<-EOT
    IAM principal ARNs (users, or another account's roles) trusted to assume the
    break-glass emergency-admin role. Keep this list short and MFA-enforced; the
    role grants AdministratorAccess.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.break_glass_principal_arns) > 0
    error_message = "At least one principal ARN must be able to assume the break-glass role, or it can never be used in an emergency."
  }
}

variable "require_mfa_for_break_glass" {
  description = "Require an active MFA session to assume the break-glass role. Strongly recommended."
  type        = bool
  default     = true
}

variable "readonly_principal_arns" {
  description = "IAM principal ARNs trusted to assume the least-privilege read-only auditor role."
  type        = list(string)
  default     = []
}

variable "password_policy" {
  description = "Baseline IAM account password policy."
  type = object({
    minimum_password_length        = optional(number, 14)
    require_lowercase_characters   = optional(bool, true)
    require_uppercase_characters   = optional(bool, true)
    require_numbers                = optional(bool, true)
    require_symbols                = optional(bool, true)
    allow_users_to_change_password = optional(bool, true)
    max_password_age               = optional(number, 90)
    password_reuse_prevention      = optional(number, 24)
  })
  default = {}
}

variable "enable_config_recorder" {
  description = "Whether to provision an AWS Config configuration recorder + delivery channel + governance rules."
  type        = bool
  default     = true
}

variable "config_bucket_force_destroy" {
  description = "Allow the AWS Config S3 bucket to be destroyed even when it still contains objects. Convenient for demos, unsafe for production."
  type        = bool
  default     = false
}

variable "required_tag_keys" {
  description = "Tag keys enforced by the AWS Config 'required-tags' governance rule."
  type        = list(string)
  default     = ["Environment", "Project"]

  validation {
    condition     = length(var.required_tag_keys) <= 6
    error_message = "The AWS Config required-tags rule supports at most 6 tag keys."
  }
}

variable "tags" {
  description = "Additional tags merged onto every resource created by this module."
  type        = map(string)
  default     = {}
}
