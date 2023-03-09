
variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
}

variable "codepipeline_bucket_arn" {
  description = "ARN of s3 bucket for code pipeline"
  default     = ""
}

variable "ecr_arn" {
  description = "ARN of ecr"
  default     = ""
}

variable "cloudwatch_arn" {
  description = "ARN of cloudwatch group"
  default     = ""
}

variable "ecs_exec_bucket_name" {
  description = "ECS Exec bucket name"
}

variable "ecs_exec_kms_key_arn" {
  description = "ECS Exec kms key arn"
}
