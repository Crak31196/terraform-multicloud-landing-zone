variable "aws_region" {
  description = "AWS region to deploy the landing zone into."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Short prefix used to name every resource in this landing zone (e.g. your company/product short name)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1-32 lowercase alphanumeric characters/hyphens and cannot start or end with a hyphen."
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

variable "vpc_cidr" {
  description = "CIDR block for the landing zone VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per availability zone."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per availability zone."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "single_nat_gateway" {
  description = "Cost-guardrail switch: one shared NAT Gateway instead of one per AZ."
  type        = bool
  default     = true
}

variable "break_glass_principal_arns" {
  description = "IAM principal ARNs trusted to assume the emergency break-glass admin role."
  type        = list(string)
}

variable "key_administrators" {
  description = "IAM ARNs allowed to administer the landing zone's KMS key."
  type        = list(string)
}

variable "monthly_budget_limit_usd" {
  description = "Monthly cost guardrail budget in USD."
  type        = number
  default     = 500
}

variable "budget_notification_emails" {
  description = "Emails subscribed to budget-threshold alerts."
  type        = list(string)
}

variable "tags" {
  description = "Additional tags applied to every resource in this landing zone."
  type        = map(string)
  default     = {}
}
