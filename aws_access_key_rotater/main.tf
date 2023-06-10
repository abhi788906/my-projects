provider "aws" {
  region = var.region # Replace with your desired region
}

#Secrets Manager Configuration
module "access_key_rotater_function" {
  source             = "./modules/lambda"
  max_key_age        = var.max_access_key_age
  function_name      = var.lambda_function_name
  admin_username     = var.account_admin_username
  admin_email        = var.account_admin_email
  function_role_name = var.iam_lambda_role_name
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
