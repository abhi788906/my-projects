# =============================================================================
# Elastic IP Monitor Module - Outputs
# =============================================================================

output "lambda_function_arn" {
  description = "ARN of the Elastic IP monitoring Lambda function"
  value       = aws_lambda_function.elastic_ip_monitor.arn
}

output "lambda_function_name" {
  description = "Name of the Elastic IP monitoring Lambda function"
  value       = aws_lambda_function.elastic_ip_monitor.function_name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule for Elastic IP allocation"
  value       = aws_cloudwatch_event_rule.elastic_ip_allocation.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule for Elastic IP allocation"
  value       = aws_cloudwatch_event_rule.elastic_ip_allocation.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard for monitoring"
  value       = aws_cloudwatch_dashboard.elastic_ip_monitoring.dashboard_name
}

output "lambda_layer_arn" {
  description = "ARN of the Lambda layer"
  value       = aws_lambda_layer_version.elastic_ip_monitor.arn
}

output "lambda_layer_name" {
  description = "Name of the Lambda layer"
  value       = aws_lambda_layer_version.elastic_ip_monitor.layer_name
}

output "lambda_layer_version" {
  description = "Version of the Lambda layer"
  value       = aws_lambda_layer_version.elastic_ip_monitor.version
}
