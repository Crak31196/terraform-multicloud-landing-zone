output "break_glass_role_arn" {
  description = "ARN of the break-glass emergency admin role."
  value       = aws_iam_role.break_glass.arn
}

output "readonly_auditor_role_arn" {
  description = "ARN of the least-privilege read-only auditor role."
  value       = aws_iam_role.readonly_auditor.arn
}

output "config_recorder_name" {
  description = "Name of the AWS Config configuration recorder (null if disabled)."
  value       = var.enable_config_recorder ? aws_config_configuration_recorder.this[0].name : null
}

output "config_bucket_name" {
  description = "Name of the S3 bucket receiving AWS Config snapshots (null if disabled)."
  value       = var.enable_config_recorder ? aws_s3_bucket.config[0].bucket : null
}

output "config_rule_names" {
  description = "Names of the AWS Config governance rules created (empty if disabled)."
  value = var.enable_config_recorder ? [
    aws_config_config_rule.required_tags[0].name,
    aws_config_config_rule.s3_public_read_prohibited[0].name,
  ] : []
}
