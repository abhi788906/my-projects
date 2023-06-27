provider "aws" {
  region = var.region # Replace with your desired region
}

module "access_key_rotater_function" {
  source             = "./modules/lambda"
  max_key_age        = var.max_access_key_age
  function_name      = var.lambda_function_name
  admin_username     = var.account_admin_username
  admin_email        = var.account_admin_email
  function_role_name = var.iam_lambda_role_name
  admin_group_name = var.admin_group
  tag_key = var.user_skip_tag_key
  tag_value = var.user_skip_tag_value
  vpc_id             = var.existing_vpc ? var.vpc_id : module.vpc[0].vpc_id
  # security_group =  var.existing_vpc ? var.security_group_id : module.vpc[0].lambda_sg
  subnet_id = var.existing_vpc ? var.subnet_id : module.vpc[0].subnet_id
  vpc_cidr  = var.existing_vpc ? var.existing_vpc_cidr : var.vpc_cidr
  expire_key_age = var.delete_key_age
}

module "vpc" {
  source              = "./modules/vpc"
  cidr                = var.vpc_cidr
  public_subnet_cidr  = var.vpc_public_subnet_cidr
  private_subnet_cidr = var.vpc_private_subnet_cidr

  # Only create resources if an existing VPC configuration is not provided
  count = var.existing_vpc == true ? 0 : 1
}

module "scheduler" {
  source          = "./modules/scheduler"
  scheduler_name  = var.cloudwatch_event_rule_name
  cron_expression = var.cloudwatch_event_rule_cron_expression
  lambda_arn      = module.access_key_rotater_function.access_key_rotater_function_arn
  function_name   = var.lambda_function_name
  depends_on      = [module.access_key_rotater_function]
}

module "email_scheduler" {
  source = "./modules/ses"
  mails  = var.email_addresses
}
