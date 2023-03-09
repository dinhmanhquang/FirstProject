
output "access_log_bucket_id" {
  description = "The ID of the bucket for access log"
  value       = module.access_log_s3_bucket.s3_bucket_id
}

output "pipeline_artifact_bucket_id" {
  description = "The ID of the bucket for pipeline artifact"
  value       = module.pipeline_artifact_s3_bucket.s3_bucket_id
}

output "pipeline_artifact_bucket_arn" {
  description = "ARN of the bucket for pipeline artifact"
  value       = module.pipeline_artifact_s3_bucket.s3_bucket_arn
}

output "vpc_flow_log_arn" {
  description = "ARN of the bucket for vpc flow logging"
  value       = module.vpc_flow_s3_bucket.s3_bucket_arn
}

output "cloudtrail_bucket_id" {
  description = "The ID of the bucket for cloudtrail"
  value       = module.cloutrail_bucket.s3_bucket_id
}

output "athena_output_bucket_id" {
  description = "The ID of the bucket for athena"
  value       = module.athena_output_s3_bucket.s3_bucket_id
}

output "access_log_bucket_name" {
  description = "The Name of the bucket for access log"
  value       = module.access_log_s3_bucket.s3_bucket_id
}

output "ecs_exec_bucket_name" {
  description = "The Name of the bucket for ECS exec log"
  value       = aws_s3_bucket.exec_ssh.bucket
}

output "cloudwatch_log_groups_id" {
  description = "The Name of the bucket for Cloudwatch groups"
  value       = module.cloudwatch_log_groups.s3_bucket_id
}

output "codebuild_bucket_name_id" {
  description = "The Name of the bucket for Codebuild"
  value       = module.codebuild_bucket_name.s3_bucket_id
}