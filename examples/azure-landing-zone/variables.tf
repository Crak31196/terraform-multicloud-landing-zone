variable "name_prefix" {
  description = "Short prefix used to name every resource in this landing zone."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,20}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1-22 lowercase alphanumeric characters/hyphens and cannot start or end with a hyphen (Key Vault naming is the limiting factor)."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "eastus"
}

variable "address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnets" {
  description = "Map of subnet name => address prefixes."
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    app = { address_prefixes = ["10.1.1.0/24"] }
    db  = { address_prefixes = ["10.1.2.0/24"] }
  }
}

variable "rbac_admin_object_ids" {
  description = "Azure AD object IDs granted Key Vault Administrator on the landing zone vault."
  type        = list(string)
  default     = []
}

variable "role_assignments" {
  description = "Baseline RBAC role assignments to create at the subscription/resource-group scope."
  type = list(object({
    principal_id         = string
    role_definition_name = string
  }))
  default = []
}

variable "required_tag_keys" {
  description = "Tag keys enforced by the require-tags governance policy."
  type        = list(string)
  default     = ["environment", "owner", "project"]
}

variable "policy_effect" {
  description = "Effect for the governance policies: Deny or Audit."
  type        = string
  default     = "Audit"
}

variable "tags" {
  description = "Additional tags applied to every resource in this landing zone."
  type        = map(string)
  default     = {}
}
