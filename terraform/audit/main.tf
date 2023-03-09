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

module "securityhub" {
  source      = "cloudposse/security-hub/aws"
  environment = "ap-northeast-1"
  enabled_standards = [
    "standards/aws-foundational-security-best-practices/v/1.0.0",
    "ruleset/cis-aws-foundations-benchmark/v/1.2.0",
    "standards/pci-dss/v/3.2.1"
  ]
}
