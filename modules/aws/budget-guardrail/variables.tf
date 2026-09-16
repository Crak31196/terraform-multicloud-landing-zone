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

variable "monthly_budget_limit_usd" {
  description = "Monthly cost budget in USD. This is a guardrail, not a hard spending cap -- it only alerts."
  type        = number

  validation {
    condition     = var.monthly_budget_limit_usd > 0
    error_message = "monthly_budget_limit_usd must be greater than 0."
  }
}

variable "alert_thresholds_percent" {
  description = "Percent-of-budget thresholds that trigger a notification (e.g. [50, 80, 100])."
  type        = list(number)
  default     = [50, 80, 100]

  validation {
    condition     = length(var.alert_thresholds_percent) > 0 && alltrue([for t in var.alert_thresholds_percent : t > 0 && t <= 500])
    error_message = "alert_thresholds_percent must contain at least one value, each between 1 and 500."
  }
}

variable "notification_emails" {
  description = "Email addresses subscribed to the budget-alert SNS topic."
  type        = list(string)

  validation {
    condition     = length(var.notification_emails) > 0
    error_message = "At least one notification email is required, otherwise budget alerts go nowhere."
  }

  validation {
    condition     = alltrue([for e in var.notification_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Every entry in notification_emails must look like a valid email address."
  }
}

variable "tags" {
  description = "Additional tags merged onto every resource created by this module."
  type        = map(string)
  default     = {}
}
