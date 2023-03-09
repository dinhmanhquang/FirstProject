
output "log_group_codebuild_arn" {
  description = "ARN of cloud watch group for codebuild"
  value       = aws_cloudwatch_log_group.codebuild.arn
}

output "log_group_codebuild_name" {
  description = "Name of cloud watch group for codebuild"
  value       = aws_cloudwatch_log_group.codebuild.name
}

output "log_group_ecs_name" {
  description = "Name of cloud watch group for ecs"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_waf_arn" {
  description = "ARN of cloud watch group for waf"
  value       = aws_cloudwatch_log_group.waf.arn
}

output "log_group_waf_name" {
  description = "Name of cloud watch group for waf"
  value       = aws_cloudwatch_log_group.waf.name
}

output "log_group_ecs_exec_arn" {
  description = "ARN of cloud watch group for ecs_exec"
  value       = aws_cloudwatch_log_group.ecs_exec.arn
}

output "log_group_ecs_exec_name" {
  description = "Name of cloud watch group for ecs_exec"
  value       = aws_cloudwatch_log_group.ecs_exec.name
}
