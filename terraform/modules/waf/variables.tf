variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
}

variable "alb_arn" {
  description = "ARN of alb"
  default     = ""
}

variable "aws_cloudwatch_log_group_arn" {
  description = "ARN of cloudwatch log group"
  default     = ""
}

variable "country_code" {
  description = "The list of restricted country"
  default     = []
}