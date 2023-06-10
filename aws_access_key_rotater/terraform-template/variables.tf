# 1 Define Region for the solution to deploy
variable "region" {
  default     = "us-east-1"
  description = "Provide the region where you want to deploy the solution"
}

# Lambda Configuration
variable "lambda_function_name" {
  default     = "user-access-key-rotater"
  description = "Name of the Lambda Function(Optional))"
}

variable "iam_lambda_role_name" {
  default     = "key-rotater-role"
  description = "Name of IAM role for the Lambda function"
}

variable "account_admin_username" {
  default     = "User Admin"
  description = "Add the Username of Admin."
}

variable "account_admin_email" {
  default     = "abhi133182@gmail.com"
  description = "Procide Email of the account Admin"
}

variable "max_access_key_age" {
  default     = 90
  type        = number
  description = "Provide the the key age after which you want to get it rotated"
}

# 3 Event Rule Configuration
variable "cloudwatch_event_rule_name" {
  default     = "access_key_scheduler"
  description = "Name of the cloudwatch event"
}

variable "cloudwatch_event_rule_cron_expression" {
  default = "cron(0 0 1 * ? *)"
}

# 4 EMAIL Configuration (SES)
variable "email_addresses" {
  type = list(string)
  default = [
    "Email1@domain.com",
    "Email2@domain.com"
    # Add more email addresses as needed
  ]
}