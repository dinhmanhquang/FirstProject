output "ecs_exec_kms_arn" {
  description = "ARN of ecs exec kms"
  value       = aws_kms_key.ecs_exec.arn
}