output "api_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_arn" {
  description = "API Gateway ARN"
  value       = aws_api_gateway_rest_api.main.arn
}

output "api_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_url" {
  description = "API Gateway URL"
  value       = "${aws_api_gateway_rest_api.main.execution_arn}/*"
}

output "deployment_url" {
  description = "Deployed API URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.main.stage_name}"
}

output "cognito_authorizer_id" {
  description = "Cognito Authorizer ID"
  value       = aws_api_gateway_authorizer.cognito.id
}

# Data source for current region
data "aws_region" "current" {}
