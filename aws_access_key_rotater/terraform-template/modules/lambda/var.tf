variable "function_name" {
    default = ""
}

variable "max_key_age" {
    default = ""
}

variable "admin_username" {
    default = ""
}

variable "admin_email" {
    default = ""
}

variable "function_role_name" {
    default = ""
}

variable "vpc_id" {
  description = "VPC ID"
  default = ""
}

variable "subnet_id" {
  description = "Subnet IDs"
  default = ""
  type = string
}

variable "security_group" {
    default = ""
}

variable "vpc_cidr" {
    default = ""
}

variable "expire_key_age" {
    default = ""
}

variable "admin_group_name" {
    default = ""
}

variable "tag_key" {
    default = ""
}

variable "tag_value" {
    default = ""
}