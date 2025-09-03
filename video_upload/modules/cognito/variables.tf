variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "password_policy" {
  description = "Password policy configuration"
  type = object({
    minimum_length                   = number
    require_uppercase               = bool
    require_lowercase               = bool
    require_numbers                 = bool
    require_symbols                 = bool
    temporary_password_validity_days = number
  })
  default = {
    minimum_length                   = 8
    require_uppercase               = true
    require_lowercase               = true
    require_numbers                 = true
    require_symbols                 = true
    temporary_password_validity_days = 7
  }
}

variable "mfa_configuration" {
  description = "MFA configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

variable "advanced_security" {
  description = "Advanced security features"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

variable "lambda_triggers" {
  description = "Lambda triggers configuration"
  type = object({
    enabled                    = bool
    pre_authentication_arn     = string
    post_authentication_arn    = string
    pre_token_generation_arn   = string
  })
  default = {
    enabled                    = false
    pre_authentication_arn     = ""
    post_authentication_arn    = ""
    pre_token_generation_arn   = ""
  }
}

variable "callback_urls" {
  description = "Callback URLs for OAuth"
  type        = list(string)
  default     = ["http://localhost:3000/callback", "https://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "Logout URLs for OAuth"
  type        = list(string)
  default     = ["http://localhost:3000/logout", "https://localhost:3000/logout"]
}

variable "token_validity" {
  description = "Token validity configuration"
  type = object({
    access_token_hours  = number
    id_token_hours      = number
    refresh_token_days  = number
  })
  default = {
    access_token_hours  = 1
    id_token_hours      = 1
    refresh_token_days  = 30
  }
}

variable "allow_unauthenticated_identities" {
  description = "Allow unauthenticated identities"
  type        = bool
  default     = false
}

variable "supported_login_providers" {
  description = "Supported login providers"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for user access"
  type        = string
}

variable "video_upload_lambda_arn" {
  description = "Video upload Lambda function ARN"
  type        = string
}

variable "multipart_init_lambda_arn" {
  description = "Multipart init Lambda function ARN"
  type        = string
}

variable "multipart_complete_lambda_arn" {
  description = "Multipart complete Lambda function ARN"
  type        = string
}
