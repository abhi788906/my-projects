# 1 Define Region for the solution to deploy
variable "region" {
  default     = "us-east-1"
  description = "Provide the region where you want to deploy the solution"
}
# VPC Configuration
# if VPC exists
variable "existing_vpc" {
  description = "If using existing VPC then set it to true"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "The ID of the existing VPC to use"
  type        = string
  default     = ""
}

variable "existing_vpc_cidr" {
  default = ""
}

variable "subnet_id" {
  description = "The subnet ID within VPC where you want to put lambda function"
  default     = ""
}

# If you want to create new VPC
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "vpc_private_subnet_cidr" {
  default = "10.0.2.0/24"
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

variable "user_skip_tag_key" {
  default = "skip"
}

variable "user_skip_tag_value" {
  default = "true"
}

variable "account_admin_username" {
  default     = "User Admin"
  description = "Add the Username of Admin."
}

# Admin Group Name
variable "admin_group" {
  default = "Default Admin Group Name" #Replace
  description = "Admin Group"
}

variable "account_admin_email" {
  default     = "email@gmail.com"
  description = "Provide Email of the account Admin"
}

variable "max_access_key_age" {
  default     = 90
  type        = number
  description = "Provide the key age after which you want to get it rotated"
}

variable "delete_key_age" {
  default = 100
  type  = number
  description = "Mention the key age after which you want to delete it"
}

# 3 Event Rule Configuration
variable "cloudwatch_event_rule_name" {
  default     = "access_key_scheduler"
  description = "Name of the cloudwatch event"
}

variable "cloudwatch_event_rule_cron_expression" {
  default = "cron(0 0 1 * ? *)"
}

# 4 EMAIL Configuration (SES
variable "email_addresses" {
  type = list(string)
  default = [
    "Email1@domain.com",
    "Email2@domain.com"
    # Add more email addresses as needed
  ]
}