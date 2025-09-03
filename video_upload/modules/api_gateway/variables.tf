variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "video_upload_lambda_invoke_arn" {
  description = "Video upload Lambda function invoke ARN"
  type        = string
}

variable "multipart_init_lambda_invoke_arn" {
  description = "Multipart init Lambda function invoke ARN"
  type        = string
}

variable "multipart_complete_lambda_invoke_arn" {
  description = "Multipart complete Lambda function invoke ARN"
  type        = string
}

variable "video_upload_lambda_function_name" {
  description = "Video upload Lambda function name"
  type        = string
}

variable "multipart_init_lambda_function_name" {
  description = "Multipart init Lambda function name"
  type        = string
}

variable "multipart_complete_lambda_function_name" {
  description = "Multipart complete Lambda function name"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
}
