
resource "aws_appautoscaling_target" "ecs" {
  service_namespace  = "ecs"
  resource_id        = var.resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 2
  max_capacity       = 10
}

resource "aws_appautoscaling_policy" "ecs_scale_up" {
  name               = "${var.name}_ecs_scale_up"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_scale_down" {
  name               = "${var.name}_ecs_scale_down"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name        = "${var.name}_cpu_utilization_high"
  alarm_description = "High CPU"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.ecs_service_name
  }
  alarm_actions             = [aws_appautoscaling_policy.ecs_scale_up.arn, var.action]
  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name        = "${var.name}_memory_utilization_high"
  alarm_description = "High Memory"

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  threshold                 = "60"
  alarm_actions             = [var.action]
  ok_actions                = [var.action]
  insufficient_data_actions = [var.action]

  metric_query {
    id          = "${var.name}_memory_utilization"
    label       = "${var.name} Memory Utilization"
    return_data = "true"
    metric {
      metric_name = "MemoryUtilization"
      namespace   = "AWS/ECS"
      stat        = "Average"
      period      = "120"
      dimensions = {
        ClusterName = var.cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }
}
