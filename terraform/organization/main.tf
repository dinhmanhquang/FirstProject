terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.41.0"
    }
  }
}
provider "aws" {
  shared_credentials_file = "./.aws"
  region                  = "ap-northeast-1"
}
terraform {
  backend "s3" {
    bucket                  = "jitera-exported-projects-organization"
    key                     = "jitera-exported-project-organization/terraform.tfstate"
    region                  = "ap-northeast-1"
    shared_credentials_file = "./.aws"
  }
}

module "member_account" {
  source                   = "../modules/organizations_account"
  management_account_name  = var.management_account_name
  management_account_email = var.management_account_email
}

module "cost_billing_alarm" {
  source                    = "binbashar/cost-billing-alarm/aws"
  version                   = "1.0.9"
  aws_env                   = "root"
  monthly_billing_threshold = var.monthly_billing_threshold
  currency                  = var.currency
}
resource "aws_sns_topic_policy" "default_topic" {
  arn = module.cost_billing_alarm.sns_topic_arn

  policy = data.aws_iam_policy_document.aws_sns_topic_policy.json
}

data "aws_iam_policy_document" "aws_sns_topic_policy" {
  statement {
    sid    = "AWSBudgetsSNSPublishingPermissions"
    effect = "Allow"

    actions = [
      "SNS:Subscribe",
      "SNS:Receive",
      "SNS:Publish"
    ]
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    resources = [
      module.cost_billing_alarm.sns_topic_arn
    ]
  }
}
