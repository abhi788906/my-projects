terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.11"
    }
  }
}

# Load configuration
locals {
  config = jsondecode(file("${path.module}/config.json"))
}

provider "aws" {
  region = local.config.project.region
  
  default_tags {
    tags = local.config.project.tags
  }
}

# VPC and Networking Module
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr             = local.config.networking.vpc_cidr
  public_subnets       = local.config.networking.public_subnets
  private_subnets      = local.config.networking.private_subnets
  availability_zones   = local.config.networking.availability_zones
  flow_logs            = local.config.networking.flow_logs
  project_name         = local.config.project.name
  environment          = local.config.project.environment
}

# KMS Module for encryption
module "kms" {
  source = "./modules/kms"
  
  enabled              = local.config.security.kms.enabled
  key_rotation         = local.config.security.kms.key_rotation
  deletion_window      = local.config.security.kms.deletion_window
  project_name         = local.config.project.name
  environment          = local.config.project.environment
}

# S3 Storage Module
module "storage" {
  source = "./modules/storage"
  
  bucket_name          = local.config.s3.bucket_name
  max_file_size_mb     = local.config.s3.max_file_size_mb
  allowed_video_formats = local.config.s3.allowed_video_formats
  multipart_upload     = local.config.s3.multipart_upload
  versioning           = local.config.s3.versioning
  encryption           = local.config.s3.encryption
  lifecycle_config     = local.config.s3.lifecycle
  access_control       = local.config.s3.access_control
  block_public_access  = local.config.s3.block_public_access
  project_name         = local.config.project.name
  environment          = local.config.project.environment
  
  # These will be updated after Lambda creation
  lambda_function_arn  = ""
  lambda_function_name = ""
}

# Lambda Functions Module
module "lambda" {
  source = "./modules/lambda"
  
  runtime              = local.config.lambda.runtime
  timeout              = local.config.lambda.timeout
  memory_size          = local.config.lambda.memory_size
  reserved_concurrency = local.config.lambda.reserved_concurrency
  environment          = local.config.lambda.environment
  project_name         = local.config.project.name
  env_name             = local.config.project.environment
  
  vpc_id               = module.networking.vpc_id
  private_subnet_ids   = module.networking.private_subnet_ids
  s3_bucket_name       = module.storage.bucket_name
  s3_bucket_arn        = module.storage.bucket_arn
  lambda_security_group_id = module.networking.lambda_security_group_id
  kms_key_id           = module.kms.key_id
}

# Cognito User Pool Module
module "cognito" {
  source = "./modules/cognito"
  
  project_name         = local.config.project.name
  environment          = local.config.project.environment
  password_policy      = local.config.cognito.password_policy
  mfa_configuration    = local.config.cognito.mfa_configuration
  advanced_security    = local.config.cognito.advanced_security
  lambda_triggers      = local.config.cognito.lambda_triggers
  callback_urls        = local.config.cognito.callback_urls
  logout_urls          = local.config.cognito.logout_urls
  token_validity       = local.config.cognito.token_validity
  allow_unauthenticated_identities = local.config.cognito.allow_unauthenticated_identities
  supported_login_providers = local.config.cognito.supported_login_providers
  s3_bucket_arn        = module.storage.bucket_arn
  video_upload_lambda_arn = module.lambda.video_upload_function_arn
  multipart_init_lambda_arn = module.lambda.multipart_init_function_arn
  multipart_complete_lambda_arn = module.lambda.multipart_complete_function_arn
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"
  
  project_name         = local.config.project.name
  environment          = local.config.project.environment
  video_upload_lambda_invoke_arn = module.lambda.video_upload_function_invoke_arn
  multipart_init_lambda_invoke_arn = module.lambda.multipart_init_function_invoke_arn
  multipart_complete_lambda_invoke_arn = module.lambda.multipart_complete_function_invoke_arn
  video_upload_lambda_function_name = module.lambda.video_upload_function_name
  multipart_init_lambda_function_name = module.lambda.multipart_init_function_name
  multipart_complete_lambda_function_name = module.lambda.multipart_complete_function_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "s3_bucket_name" {
  description = "S3 bucket name for video storage"
  value       = module.storage.bucket_name
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = module.kms.key_arn
}

output "lambda_function_names" {
  description = "Lambda function names"
  value = [
    module.lambda.video_upload_function_name,
    module.lambda.multipart_init_function_name,
    module.lambda.multipart_complete_function_name
  ]
}

output "api_gateway_url" {
  description = "API Gateway deployment URL"
  value       = module.api_gateway.deployment_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.user_pool_client_id
}

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = module.cognito.identity_pool_id
}

output "cognito_domain_url" {
  description = "Cognito User Pool Domain URL"
  value       = module.cognito.user_pool_domain_url
}
