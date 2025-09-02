# =============================================================================
# CloudTrail Module - Outputs
# =============================================================================

output "trail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "trail_name" {
  description = "Name of the CloudTrail"
  value       = aws_cloudtrail.main.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket used for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket used for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.arn
}

output "s3_key_prefix" {
  description = "S3 key prefix used for CloudTrail logs"
  value       = aws_cloudtrail.main.s3_key_prefix
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group (if enabled)"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group (if enabled)"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
}

output "cloudtrail_cloudwatch_role_arn" {
  description = "ARN of the CloudTrail CloudWatch role (if enabled)"
  value       = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_cloudwatch[0].arn : null
}
