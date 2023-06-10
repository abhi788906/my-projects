output "access_key_rotater_function_arn" {
  value       = aws_lambda_function.access_key_rotater.arn
  description = "Function ARN for cross-reference"
}
