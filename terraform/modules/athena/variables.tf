variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
}

variable "athena_output_bucket_name" {
  description = "Name to be used on s3 bucket name for athena"
}

variable "athena_output_bucket_id" {
  description = "The ID of the bucket for athena"
}

variable "cloudtrail_bucket_name" {
  description = "Name to be used on s3 bucket name for cloudtrail"
}

variable "access_log_bucket_name" {
  description = "Name to be used on s3 bucket name for alb access log"
}

variable "aws_account_id" {
  description = "AWS Account ID"
}