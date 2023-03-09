variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
}

variable "aws_account_id" {
  description = "AWS Account ID"
}

variable "bucket_name" {
  description = "Name of S3 bucket"
}

variable "s3_user_arn" {
  description = "ARN of s3 User"
}
