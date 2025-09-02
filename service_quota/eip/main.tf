# =============================================================================
# Elastic IP Monitoring Infrastructure - Main Configuration
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Local configuration data
locals {
  config = jsondecode(file("${path.module}/config.json"))
  
  # Common tags
  common_tags = merge(
    local.config.common_tags,
    {
      Environment = local.config.environment
      Project     = local.config.project_name
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  )
}

# AWS Provider
provider "aws" {
  region = local.config.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# CloudTrail Module
module "cloudtrail" {
  source = "./modules/cloudtrail"
  
  project_name = local.config.project_name
  trail_name   = "${local.config.project_name}-elastic-ip-trail-${random_id.suffix.hex}"
  bucket_name  = "${local.config.project_name}-cloudtrail-${random_id.suffix.hex}"
  
  s3_key_prefix           = "elastic-ip-monitoring"
  include_global_events   = local.config.cloudtrail.include_global_events
  is_multi_region         = local.config.cloudtrail.is_multi_region
  enable_logging          = local.config.cloudtrail.enable_logging
  enable_cloudwatch_logs  = local.config.cloudtrail.enable_cloudwatch_logs
  log_retention_days      = local.config.cloudtrail.log_retention_days
  cloudwatch_log_retention_days = local.config.cloudtrail.cloudwatch_log_retention_days
  
  tags = local.common_tags
}

# Elastic IP Monitor Module
module "elastic_ip_monitor" {
  source = "./modules/elastic-ip-monitor"
  
  module_name = local.config.project_name
  
  aws_region                = local.config.aws_region
  lambda_function_zip_path  = local.config.lambda.function_zip_path
  lambda_layer_zip_path     = local.config.lambda.layer_zip_path
  lambda_runtime            = local.config.lambda.runtime
  lambda_timeout            = local.config.lambda.timeout
  lambda_memory_size        = local.config.lambda.memory_size
  
  log_level                 = local.config.lambda.log_level
  quota_code                = local.config.lambda.quota_code
  service_code              = local.config.lambda.service_code
  usage_threshold           = local.config.lambda.usage_threshold
  quota_increment           = local.config.lambda.quota_increment
  enable_quota_increase     = local.config.lambda.enable_quota_increase
  sns_topic_arn            = local.config.lambda.sns_topic_arn
  cloudwatch_log_retention_days = local.config.lambda.cloudwatch_log_retention_days
  
  tags = local.common_tags
}
