output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "user_pool_client_secret" {
  description = "Cognito User Pool Client Secret"
  value       = aws_cognito_user_pool_client.main.client_secret
  sensitive   = true
}

output "identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.main.id
}

output "identity_pool_arn" {
  description = "Cognito Identity Pool ARN"
  value       = aws_cognito_identity_pool.main.arn
}

output "authenticated_role_arn" {
  description = "Authenticated user IAM role ARN"
  value       = aws_iam_role.authenticated.arn
}

output "unauthenticated_role_arn" {
  description = "Unauthenticated user IAM role ARN"
  value       = var.allow_unauthenticated_identities ? aws_iam_role.unauthenticated[0].arn : null
}

output "user_pool_domain" {
  description = "Cognito User Pool Domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "user_pool_domain_url" {
  description = "Cognito User Pool Domain URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

output "admin_group_name" {
  description = "Admin group name"
  value       = aws_cognito_user_group.admin.name
}

output "user_group_name" {
  description = "User group name"
  value       = aws_cognito_user_group.user.name
}

# Data source for current region
data "aws_region" "current" {}
