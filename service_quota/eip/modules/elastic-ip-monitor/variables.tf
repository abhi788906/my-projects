# =============================================================================
# Elastic IP Monitor Module - Variables
# =============================================================================

variable "module_name" {
  description = "Name prefix for the module resources"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.module_name))
    error_message = "Module name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_zip_path" {
  description = "Path to the Lambda function ZIP file"
  type        = string
  
  validation {
    condition     = can(regex("\\.zip$", var.lambda_function_zip_path))
    error_message = "Lambda function path must be a ZIP file."
  }
}

variable "lambda_layer_zip_path" {
  description = "Path to the Lambda layer ZIP file"
  type        = string
  
  validation {
    condition     = can(regex("\\.zip$", var.lambda_layer_zip_path))
    error_message = "Lambda layer path must be a ZIP file."
  }
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = list(string)
  default     = ["python3.9"]
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
  
  validation {
    condition     = var.lambda_timeout >= 3 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 3 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
  
  validation {
    condition     = contains([128, 256, 512, 1024, 2048, 4096, 10240], var.lambda_memory_size)
    error_message = "Lambda memory size must be one of the allowed values: 128, 256, 512, 1024, 2048, 4096, 10240."
  }
}

variable "log_level" {
  description = "Log level for the Lambda function"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
}

variable "quota_code" {
  description = "AWS Service Quotas code for Elastic IPs"
  type        = string
  default     = "L-0263D0A3"
}

variable "service_code" {
  description = "AWS service code for EC2"
  type        = string
  default     = "ec2"
}

variable "usage_threshold" {
  description = "Usage threshold percentage to trigger quota increase"
  type        = number
  default     = 50.0
  
  validation {
    condition     = var.usage_threshold > 0 && var.usage_threshold <= 100
    error_message = "Usage threshold must be between 0 and 100."
  }
}

variable "quota_increment" {
  description = "Number of quota units to increase by"
  type        = number
  default     = 1
  
  validation {
    condition     = var.quota_increment > 0
    error_message = "Quota increment must be greater than 0."
  }
}

variable "enable_quota_increase" {
  description = "Whether to enable automatic quota increase requests"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for notifications (optional)"
  type        = string
  default     = null
  
  validation {
    condition     = var.sns_topic_arn == null || can(regex("^arn:aws:sns:", var.sns_topic_arn))
    error_message = "SNS topic ARN must be a valid SNS ARN or null."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention must be one of the allowed values."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
