variable "name" {
  description = "short description of the dashboard name"
}

variable "region" {
  description = "short description of the dashboard name"
  default     = "ap-northeast-1"
}

variable "aws_alb_target_group_blue_arn_suffix" {
  description = "target group arn of web https"
}

variable "aws_alb_target_group_green_arn_suffix" {
  description = "target group arn of web https"
}

variable "aws_alb_arn_suffix" {
  description = "load balancer arn suffix"
}

variable "database_max_simultaneous_connections_warning" {
  default = 15
}

variable "db_identifier" {}


variable "database_free_storage_space_warning" {
  default = 3000000000
}

variable "redis_name" {}