output "key_id" {
  description = "ID of the KMS key."
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "ARN of the KMS key. Reference this from other resources' encryption blocks."
  value       = aws_kms_key.this.arn
}

output "alias_name" {
  description = "Alias name of the KMS key (e.g. alias/acme-prod)."
  value       = aws_kms_alias.this.name
}

output "rotation_enabled" {
  description = "Whether automatic key rotation is enabled."
  value       = aws_kms_key.this.enable_key_rotation
}
