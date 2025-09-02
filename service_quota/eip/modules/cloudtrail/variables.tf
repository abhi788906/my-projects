# =============================================================================
# CloudTrail Module - Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "Project name must contain only letters, numbers, and hyphens."
  }
}

variable "trail_name" {
  description = "Name of the CloudTrail"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.trail_name))
    error_message = "Trail name must contain only letters, numbers, and hyphens."
  }
}

variable "bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be a valid S3 bucket name."
  }
}

variable "s3_key_prefix" {
  description = "S3 key prefix for CloudTrail logs"
  type        = string
  default     = "cloudtrail-logs"
}

variable "include_global_events" {
  description = "Whether to include global service events"
  type        = bool
  default     = true
}

variable "is_multi_region" {
  description = "Whether this is a multi-region trail"
  type        = bool
  default     = false
}

variable "enable_logging" {
  description = "Whether to enable CloudTrail logging"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch logging for CloudTrail"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "S3 log retention period in days"
  type        = number
  default     = 90
  
  validation {
    condition     = var.log_retention_days >= 1
    error_message = "Log retention days must be at least 1."
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

variable "event_selectors" {
  description = "List of event selectors for CloudTrail"
  type = list(object({
    read_write_type = string
    data_resources = list(object({
      type   = string
      values = list(string)
    }))
  }))
  default = [
    {
      read_write_type = "WriteOnly"
      data_resources = [
        {
          type   = "AWS::EC2::Address"
          values = ["arn:aws:ec2:*:*:elastic-ip/*"]
        }
      ]
    }
  ]
  
  validation {
    condition = alltrue([
      for selector in var.event_selectors : 
      contains(["All", "ReadOnly", "WriteOnly"], selector.read_write_type)
    ])
    error_message = "Read write type must be one of: All, ReadOnly, WriteOnly."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
