output "video_upload_function_name" {
  description = "Video upload Lambda function name"
  value       = aws_lambda_function.video_upload.function_name
}

output "multipart_init_function_name" {
  description = "Multipart init Lambda function name"
  value       = aws_lambda_function.multipart_init.function_name
}

output "multipart_complete_function_name" {
  description = "Multipart complete Lambda function name"
  value       = aws_lambda_function.multipart_complete.function_name
}

output "video_upload_function_arn" {
  description = "Video upload Lambda function ARN"
  value       = aws_lambda_function.video_upload.arn
}

output "multipart_init_function_arn" {
  description = "Multipart init Lambda function ARN"
  value       = aws_lambda_function.multipart_init.arn
}

output "multipart_complete_function_arn" {
  description = "Multipart complete Lambda function ARN"
  value       = aws_lambda_function.multipart_complete.arn
}

output "video_upload_function_invoke_arn" {
  description = "Video upload Lambda function invoke ARN"
  value       = aws_lambda_function.video_upload.invoke_arn
}

output "multipart_init_function_invoke_arn" {
  description = "Multipart init Lambda function invoke ARN"
  value       = aws_lambda_function.multipart_init.invoke_arn
}

output "multipart_complete_function_invoke_arn" {
  description = "Multipart complete Lambda function invoke ARN"
  value       = aws_lambda_function.multipart_complete.invoke_arn
}

output "function_arns" {
  description = "All Lambda function ARNs"
  value = [
    aws_lambda_function.video_upload.arn,
    aws_lambda_function.multipart_init.arn,
    aws_lambda_function.multipart_complete.arn
  ]
}

output "execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_exec.arn
}
