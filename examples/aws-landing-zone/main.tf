# Example root module wiring the AWS baseline modules together into one landing zone.
# This is a starting point to copy into a client's own repo, not a shared multi-tenant
# stack -- each client/environment gets its own state.

module "vpc" {
  source = "../../modules/aws/vpc"

  name_prefix           = var.name_prefix
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  single_nat_gateway    = var.single_nat_gateway
  tags                  = var.tags
}

module "kms" {
  source = "../../modules/aws/kms"

  name_prefix         = var.name_prefix
  environment         = var.environment
  key_administrators  = var.key_administrators
  tags                = var.tags
}

module "iam_baseline" {
  source = "../../modules/aws/iam-baseline"

  name_prefix                = var.name_prefix
  environment                = var.environment
  break_glass_principal_arns = var.break_glass_principal_arns
  tags                       = var.tags
}

module "budget_guardrail" {
  source = "../../modules/aws/budget-guardrail"

  name_prefix              = var.name_prefix
  environment              = var.environment
  monthly_budget_limit_usd = var.monthly_budget_limit_usd
  notification_emails      = var.budget_notification_emails
  tags                     = var.tags
}
