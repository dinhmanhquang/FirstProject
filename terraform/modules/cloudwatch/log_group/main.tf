resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "${var.name}_codebuild"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${var.name}_ecs_web"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs_exec" {
  name              = "aws-ecs-exec-logs-${var.name}"
  retention_in_days = 30
}
