///////////////////////////////////////////////////////////////////////////
# Need to get the credential from AWS SSM
///////////////////////////////////////////////////////////////////////////

variable "database_password" {
  description = "Name of database password"
}

variable "rails_master_key" {
  description = "Encrypted key as rails master key"
}

variable "github_token" {
  description = "Github personal access token"
}

variable "docker_username" {
  description = "Docker Username"
}

variable "docker_password" {
  description = "Docker Password"
}

///////////////////////////////////////////////////////////////////////////
# Please update default values if needed
///////////////////////////////////////////////////////////////////////////

variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = "lu_fer"
}

variable "env" {
  description = "Environment that is used as placeholder"
  default     = "staging"
}

variable "azs" {
  description = "A list of availability zones in the region"
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

# IP architecture
# https://www.notion.so/iruuzainc/IP-architecture-85d035693086447c88fcf286f682d21b

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "10.21.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  default     = ["10.21.128.0/24", "10.21.129.0/24"]
}

variable "database_subnets" {
  description = "A list of database subnets inside the VPC"
  default     = ["10.21.192.0/26", "10.21.192.64/26"]
}

variable "elasticache_subnets" {
  description = "Elasticache Subnets"
  default     = ["10.21.193.0/26", "10.21.193.64/26"]
}


variable "database_name" {
  description = "Name of database name"
  default     = "lu_fer_staging"
}

variable "database_user" {
  description = "Name of database user"
  default     = "lu_fer_staging"
}



variable "instance_class" {
  description = "Database instance type"
  instance_class = "db.t3.micro"
}


variable "lb_healthcheck_path" {
  description = "Path of loadbalancer's health check"
  default     = "/health"
}

variable "github_account" {
  description = "Github account name of access token"
  default     = "Jitera"
}

variable "github_repository" {
  description = "Github repository to get source"
  default     = "FirstProject"
}

variable "github_branch" {
  description = "Git branch to get source"
  default     = "staging"
}

variable "zone_id" {
  description = "Zone ID"
  default     = ""
}

variable "domain" {
  description = "Domain"
  default     = "lufer-staging.project.jitera.app"
}

variable "slack_channel_id" {
  description = "Slack Channel identifier"
  default     = ""
}

variable "slack_workspace_id" {
  description = "Slack Workspace identifier"
  default     = ""
}

variable "notify_slack_webhook_url" {
  description = "Slack Webhook for Cloudwatch notification"
  default     = ""
}

variable "notify_slack_channel" {
  description = "Slack channel for Cloudwatch notificationr"
  default     = ""
}

variable "aws_account_id" {
  description = "AWS Account ID"
  default     = ""
}
# s3 storage bucket
variable "iam_user_name" {
  default = "s3-staging-user"
}

variable "bucket_name" {
  default = "lufer-staging-storage"
}

variable "country_code" {
  description = "The list of restricted country"
  default     = []
}
