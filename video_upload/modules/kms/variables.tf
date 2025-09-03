variable "enabled" {
  description = "Whether to create KMS resources"
  type        = bool
  default     = true
}

variable "key_rotation" {
  description = "Whether to enable key rotation"
  type        = bool
  default     = true
}

variable "deletion_window" {
  description = "Deletion window in days"
  type        = number
  default     = 7
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
