# =============================================================================
# Elastic IP Monitoring Infrastructure - Outputs
# =============================================================================

# CloudTrail Module Outputs
output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail"
  value       = module.cloudtrail.trail_arn
}

output "cloudtrail_trail_name" {
  description = "Name of the CloudTrail"
  value       = module.cloudtrail.trail_name
}

output "cloudtrail_s3_bucket_name" {
  description = "Name of the S3 bucket used for CloudTrail logs"
  value       = module.cloudtrail.s3_bucket_name
}

output "cloudtrail_s3_bucket_arn" {
  description = "ARN of the S3 bucket used for CloudTrail logs"
  value       = module.cloudtrail.s3_bucket_arn
}

# Elastic IP Monitor Module Outputs
output "lambda_function_arn" {
  description = "ARN of the Elastic IP monitoring Lambda function"
  value       = module.elastic_ip_monitor.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Elastic IP monitoring Lambda function"
  value       = module.elastic_ip_monitor.lambda_function_name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.elastic_ip_monitor.lambda_execution_role_arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule for Elastic IP allocation"
  value       = module.elastic_ip_monitor.eventbridge_rule_arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard for monitoring"
  value       = module.elastic_ip_monitor.cloudwatch_dashboard_name
}

output "lambda_layer_arn" {
  description = "ARN of the Lambda layer"
  value       = module.elastic_ip_monitor.lambda_layer_arn
}

# Summary Outputs
output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    project_name     = local.config.project_name
    environment      = local.config.environment
    aws_region       = local.config.aws_region
    cloudtrail_name  = module.cloudtrail.trail_name
    lambda_function  = module.elastic_ip_monitor.lambda_function_name
    s3_bucket        = module.cloudtrail.s3_bucket_name
    deployment_time  = timestamp()
  }
}
