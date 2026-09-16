variable "name_prefix" {
  description = "Short prefix used to name every resource created by this module (e.g. \"acme-prod\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1-32 lowercase alphanumeric characters/hyphens and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment. Drives the environment tag applied to every resource."
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
  description = "Name of an existing resource group to deploy the network into."
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network, e.g. [\"10.1.0.0/16\"]."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for c in var.address_space : can(cidrnetmask(c))])
    error_message = "address_space must contain at least one valid IPv4 CIDR block."
  }
}

variable "subnets" {
  description = <<-EOT
    Map of subnet name => configuration. Each subnet gets its own Network Security
    Group with a secure-by-default deny-inbound-internet rule (overridable via
    extra_nsg_rules). Example:
      {
        app = { address_prefixes = ["10.1.1.0/24"] }
        db  = { address_prefixes = ["10.1.2.0/24"] }
      }
  EOT
  type = map(object({
    address_prefixes = list(string)
    extra_nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined."
  }
}

variable "tags" {
  description = "Additional tags merged onto every resource created by this module."
  type        = map(string)
  default     = {}
}
