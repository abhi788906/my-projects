module "contacts" {
  source                   = "./modules/incident_manager"
  contacts                 = var.contacts
  schedule                 = var.schedule
  oncall_schedule_contacts = var.oncall_schedule_contacts
  escalation_plans         = var.escalation_plans
  response_plan            = var.response_plan
}

provider "aws" {
  region  = "ap-south-1"  // specify your desired region
  profile = "default"    // specify your AWS CLI profile if needed
}

provider "awscc" {
  region  = "ap-south-1"  // specify your desired region
  profile = "default"    // specify your AWS CLI profile if needed
}

terraform {
  required_providers {
    awscc = {
      source = "hashicorp/awscc"
      version = "1.20.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "5.75.1"
    }
  }
}

