output "vpc_id" {
  description = "ID of the landing zone VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "kms_key_arn" {
  description = "ARN of the landing zone's encryption-at-rest KMS key."
  value       = module.kms.key_arn
}

output "break_glass_role_arn" {
  description = "ARN of the emergency break-glass admin role."
  value       = module.iam_baseline.break_glass_role_arn
}

output "config_recorder_name" {
  description = "Name of the AWS Config configuration recorder."
  value       = module.iam_baseline.config_recorder_name
}

output "budget_name" {
  description = "Name of the cost-guardrail AWS Budget."
  value       = module.budget_guardrail.budget_name
}

output "budget_alerts_sns_topic_arn" {
  description = "SNS topic ARN receiving budget-threshold alerts."
  value       = module.budget_guardrail.sns_topic_arn
}
