output "ecs_scale_up_arn" {
  value = aws_appautoscaling_policy.ecs_scale_up.arn
}
output "ecs_scale_down_arn" {
  value = aws_appautoscaling_policy.ecs_scale_down.arn
}
