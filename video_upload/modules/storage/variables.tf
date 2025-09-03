variable "bucket_name" {
  description = "Name of the S3 bucket for video storage"
  type        = string
}

variable "max_file_size_mb" {
  description = "Maximum file size in MB"
  type        = number
  default     = 1024
}

variable "allowed_video_formats" {
  description = "List of allowed video file formats"
  type        = list(string)
  default     = ["mp4", "avi", "mov", "mkv", "wmv", "flv", "webm", "m4v"]
}

variable "multipart_upload" {
  description = "Multipart upload configuration"
  type = object({
    part_size_mb                              = number
    max_concurrent_parts                       = number
    abort_incomplete_multipart_upload_days     = number
  })
  default = {
    part_size_mb                              = 100
    max_concurrent_parts                       = 10
    abort_incomplete_multipart_upload_days     = 7
  }
}

variable "versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "encryption" {
  description = "S3 bucket encryption configuration"
  type = object({
    enabled      = bool
    algorithm    = string
    kms_key_id   = string
  })
  default = {
    enabled    = true
    algorithm  = "aws:kms"
    kms_key_id = "aws/s3"
  }
}

variable "lifecycle_config" {
  description = "S3 bucket lifecycle configuration"
  type = object({
    enabled                    = bool
    transition_to_ia_days      = number
    transition_to_glacier_days = number
    expiration_days            = number
  })
  default = {
    enabled                    = true
    transition_to_ia_days      = 30
    transition_to_glacier_days = 90
    expiration_days            = 2555
  }
}

variable "access_control" {
  description = "S3 bucket access control"
  type        = string
  default     = "private"
}

variable "block_public_access" {
  description = "Block public access to S3 bucket"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function for S3 notifications"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Name of the Lambda function for S3 notifications"
  type        = string
  default     = ""
}
