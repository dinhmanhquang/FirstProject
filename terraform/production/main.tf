provider "aws" {
  shared_credentials_file = "./.aws"
  region                  = "ap-northeast-1"
}
terraform {
  backend "s3" {
    bucket                  = ""
    key                     = "lufer-production/terraform.tfstate"
    region                  = "ap-northeast-1"
    shared_credentials_file = "./.aws"
  }
}

locals {
  # underscore is prefereble according to official terraform bestpractice, but alb only accepts hyphen based name.
  # Moreover, terraform AWS provider v3.12.0 (via Terraform 0.14) has issue #7987 related to "Provider produced inconsistent final plan".
  # It means that S3 bucket has to be created before referencing it as an argument inside access_logs = { bucket = "bucket-name" }, so this won't work: access_logs = { bucket = module.s3.s3_bucket_id }.
  hyphen_name               = replace("${var.name}", "_", "-")
}

module "route53" {
  source                    = "../modules/route53"
  zone_id                   = var.zone_id
  domain                    = var.domain
  alb_dns_name              = module.alb.dns_name
  alb_zone_id               = module.alb.zone_id
}

module "vpc" {
  source              = "../modules/vpc"
  name                = local.hyphen_name
  cidr                = var.cidr
  azs                 = var.azs
  public_subnets      = var.public_subnets
  database_subnets    = var.database_subnets
  elasticache_subnets = var.elasticache_subnets
  aws_s3_bucket_arn   = module.s3.vpc_flow_log_arn
}

module "security_group" {
  source   = "../modules/security_group"
  name     = var.name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.cidr
}

module "s3" {
  source                    = "../modules/s3"
  name                      = local.hyphen_name
  aws_account_id            = var.aws_account_id
  bucket_name               = var.bucket_name
  s3_user_arn               = module.iam.s3_user_arn
}

module "alb" {
  source               = "../modules/alb"
  name                 = local.hyphen_name
  vpc_id               = module.vpc.vpc_id
  security_groups      = [module.security_group.alb_sg_id]
  subnets              = module.vpc.public_subnets
  access_log_bucket_id = module.s3.access_log_bucket_name
  lb_healthcheck_path  = var.lb_healthcheck_path
  ssl_cert_arn         = module.route53.certificate_arn
}

module "waf" {
  source                       = "../modules/waf"
  name                         = var.name
  alb_arn                      = module.alb.web_arn
  aws_cloudwatch_log_group_arn = module.cloudwatch.log_group_waf_arn
  country_code                 = var.country_code
}


module "ecs" {
  source                             = "../modules/ecs"
  name                               = var.name
  cloudwatch_log_group_name          = module.cloudwatch.log_group_ecs_name
  image_url                          = module.ecr.web_repository_url
  lb_blue_arn                        = module.alb.target_group_blue_arn
  subnets                            = module.vpc.public_subnets
  security_groups                    = [module.security_group.app_sg_id]
  iam_arn                            = module.iam.ecs_tasks_arn
  database_host_arn                  = module.ssm.database_host_arn
  database_password_arn              = module.ssm.database_password_arn
  rails_master_key_arn               = module.ssm.rails_master_key_arn
  env                                = var.env
  redis_address_arn                  = module.ssm.redis_address_arn
  git_token_arn                      = module.ssm.git_token_arn
  ecs_exec_kms_arn                   = module.kms.ecs_exec_kms_arn
  ecs_exec_s3_bucket_name            = module.s3.ecs_exec_bucket_name
  cloudwatch_log_group_ecs_exec_name = module.cloudwatch.log_group_ecs_exec_name
}

module "autoscaling_web" {
  source           = "../modules/autoscaling"
  name             = "${var.name}"
  resource_id      = "service/${var.name}/${var.name}"
  ecs_service_name = "${var.name}"
  cluster_name     = var.name
  action           = module.notify_slack.this_slack_topic_arn

}

module "autoscaling_sidekiq" {
  source           = "../modules/autoscaling"
  name             = "${var.name}_sidkeiq"
  resource_id      = "service/${var.name}/${var.name}_sidekiq"
  cluster_name     = var.name
  ecs_service_name = "${var.name}_sidekiq"
  action           = module.notify_slack.this_slack_topic_arn

}

module "notify_slack" {
  source            = "terraform-aws-modules/notify-slack/aws"
  version           = "~> 5.4"
  sns_topic_name    = "${var.name}_cloudwatch_metrics"
  slack_webhook_url = var.notify_slack_webhook_url
  slack_channel     = var.notify_slack_channel
  slack_username    = "AWS"
  lambda_function_name = var.name
}

module "metric_alarms" {
  source                              = "../modules/cloudwatch/metric_alarms"
  aws_lb_target_group_blue_arn_suffix = module.alb.target_group_blue_arn_suffix
  aws_lb_web_arn_suffix               = module.alb.web_arn_suffix
  name                                = var.name
  action                              = module.notify_slack.this_slack_topic_arn
  db_instance_id                      = module.rds.id
  elasticache_member_clusters         = module.elasticache.elasticache_member_clusters
  waf_web_acl                         = module.waf.web_acl_name
}

module "rds" {
  source                     = "../modules/rds"
  name                       = local.hyphen_name
  env                        = var.env
  database_name              = var.database_name
  user                       = var.database_user
  password                   = var.database_password
  subnets                    = module.vpc.database_subnets
  security_groups            = [module.security_group.database_sg_id]
  database_subnet_group_name = module.vpc.database_subnet_group_name
  instance_class             = var.instance_class
}
# snapshot_identifier = var.snapshot_identifier

module "ssm" {
  source                  = "../modules/ssm"
  name                    = var.name
  database_password       = var.database_password
  database_host           = trim(module.rds.db_endpoint, ":3306")
  rails_master_key        = var.rails_master_key
  web_container_name      = var.name
  docker_username         = var.docker_username
  docker_password         = var.docker_password
  subnet                  = module.vpc.public_subnets[0]
  security_group          = module.security_group.app_sg_id
  redis_address           = "redis://${module.elasticache.cluster_address}:${module.elasticache.port}"
  git_token               = var.github_token
}

module "cloudwatch" {
  source = "../modules/cloudwatch/log_group"
  name   = var.name
}

module "ecr" {
  source   = "../modules/ecr"
  name     = var.name
}

module "iam" {
  source                  = "../modules/iam"
  name                    = var.name
  codepipeline_bucket_arn = module.s3.pipeline_artifact_bucket_arn
  cloudwatch_arn          = module.cloudwatch.log_group_codebuild_arn
  ecr_arn                 = module.ecr.web_arn
  ecs_exec_bucket_name    = module.s3.ecs_exec_bucket_name
  ecs_exec_kms_key_arn    = module.kms.ecs_exec_kms_arn
  iam_user_name           = var.iam_user_name
}

module "iam_developer" {
  source                  = "../modules/iam/developer-user"
  name                    = "limited.permission"
}

module "codepipeline" {
  source             = "../modules/codepipeline"
  name               = var.name
  env                = var.env
  iam_arn            = module.iam.codepipeline_arn
  s3_id              = module.s3.pipeline_artifact_bucket_id
  github_account     = var.github_account
  github_repository  = var.github_repository
  github_branch      = var.github_branch
  github_token       = var.github_token
  codedeploy_name    = module.codedeploy.web_name
  codebuild_name     = module.codebuild.web_name
}

module "codebuild" {
  source                    = "../modules/codebuild"
  name                      = var.name
  env                       = var.env
  vpc_id                    = module.vpc.vpc_id
  subnets                   = module.vpc.database_subnets
  security_groups           = [module.security_group.codebuild_sg_id]
  iam_arn                   = module.iam.codebuild_arn
  cloudwatch_log_group_name = module.cloudwatch.log_group_codebuild_name
}

module "codedeploy" {
  source                = "../modules/codedeploy"
  name                  = var.name
  iam_arn               = module.iam.codedeploy_arn
  ecs_web_service_name  = module.ecs.web_service_name
  alb_listner_arns      = module.alb.lb_listener_arns
  alb_target_blue_name  = module.alb.target_group_blue_name
  alb_target_green_name = module.alb.target_group_green_name
}

module "elasticache" {
  env                 = var.env
  azs                 = var.azs
  source              = "../modules/elasticache"
  name                = local.hyphen_name
  elasticache_subnets = module.vpc.elasticache_subnet_group_name
  security_groups     = [module.security_group.redis_security_group_id]
}

module "codepipeline_notification" {
  source               = "../modules/sns"
  name                 = var.name
  slack_channel_id     = var.slack_channel_id
  slack_workspace_id   = var.slack_workspace_id
  aws_codepipeline_arn = module.codepipeline.codepipeline_web_arn
}

module "kms" {
  source = "../modules/kms"
}

module "dashboard" {
  source                                = "../modules/cloudwatch/dashboard"
  name                                  = var.name
  aws_alb_target_group_blue_arn_suffix  = module.alb.target_group_blue_arn_suffix
  aws_alb_target_group_green_arn_suffix = module.alb.target_group_green_arn_suffix
  aws_alb_arn_suffix                    = module.alb.web_arn_suffix
  db_identifier                         = module.rds.id
  redis_name                            = module.elasticache.name
}

module "cloudwatch-logs-exporter" {
  source    = "../modules/cloudwatch/exporter"
  name      = "${var.name}_cloudwatch_logs"
  log_group = module.cloudwatch.log_group_ecs_name
  s3_bucket = module.s3.cloudwatch_log_groups_id
  schedule  = "cron(0 19 ? * 3 *)"
}

module "codebuild-log" {
  source    = "../modules/cloudwatch/exporter"
  name      = "${var.name}_codebuild_log"
  log_group = module.cloudwatch.log_group_codebuild_name
  s3_bucket = module.s3.codebuild_bucket_name_id
  schedule  = "cron(0 10 * * ? *)"
}

module "athena" {
  source                    = "../modules/athena"
  name                      = var.name
  athena_output_bucket_name = module.s3.athena_output_bucket_id
  athena_output_bucket_id   = module.s3.athena_output_bucket_id
  cloudtrail_bucket_name    = module.s3.cloudtrail_bucket_id
  access_log_bucket_name    = module.s3.access_log_bucket_name
  aws_account_id            = var.aws_account_id
}

module "cloudtrail" {
  source               = "../modules/cloudtrail"
  name                 = var.name
  cloudtrail_bucket_id = module.s3.cloudtrail_bucket_id
}


