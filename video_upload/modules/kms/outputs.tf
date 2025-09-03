output "key_arn" {
  description = "KMS key ARN"
  value       = var.enabled ? aws_kms_key.main[0].arn : null
}

output "key_id" {
  description = "KMS key ID"
  value       = var.enabled ? aws_kms_key.main[0].id : null
}

output "alias_arn" {
  description = "KMS key alias ARN"
  value       = var.enabled ? aws_kms_alias.main[0].arn : null
}

output "alias_name" {
  description = "KMS key alias name"
  value       = var.enabled ? aws_kms_alias.main[0].name : null
}
