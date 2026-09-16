variable "name_prefix" {
  description = "Short prefix used to name every resource created by this module (e.g. \"acme-prod\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1-32 lowercase alphanumeric characters/hyphens and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment. Drives the environment tag applied to policy assignment metadata."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "policy_assignment_scope" {
  description = "Resource group ID the governance policies and RBAC role assignments are scoped to, e.g. /subscriptions/<guid>/resourceGroups/<name>."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]{36}/resourceGroups/[^/]+$", var.policy_assignment_scope))
    error_message = "policy_assignment_scope must be a resource group resource ID, e.g. /subscriptions/<guid>/resourceGroups/<name>."
  }
}

variable "role_assignments" {
  description = "Baseline RBAC role assignments to create at policy_assignment_scope."
  type = list(object({
    principal_id         = string
    role_definition_name = string
  }))
  default = []
}

variable "required_tag_keys" {
  description = "Tag keys that must be present on every resource under scope (enforced via a custom \"deny if missing\" policy)."
  type        = list(string)
  default     = ["environment", "owner", "project"]

  validation {
    condition     = length(var.required_tag_keys) > 0
    error_message = "At least one required tag key must be supplied."
  }
}

variable "deny_public_ip" {
  description = "Whether to assign a policy that denies creation of new Public IP address resources under scope."
  type        = bool
  default     = true
}

variable "policy_effect" {
  description = "Effect used for the custom policies: \"Deny\" blocks non-compliant resources, \"Audit\" only flags them. Start with Audit while onboarding, move to Deny once clean."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Deny", "Audit"], var.policy_effect)
    error_message = "policy_effect must be \"Deny\" or \"Audit\"."
  }
}
