locals {
  // underscore is prefereble according to official terraform bestpractice, but alb only accepts hyphen based name.
  resources_name = trimsuffix(substr(replace("${var.name}_web", "_", "-"), 0, 25), "-")
}

resource "aws_lb" "web" {
  name                       = local.resources_name
  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = false
  security_groups            = var.security_groups
  subnets                    = var.subnets
  access_logs {
    bucket  = var.access_log_bucket_id
    enabled = true
  }
  tags = {
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "blue" {
  name        = "${local.resources_name}-blue"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    protocol            = "HTTP"
    path                = var.lb_healthcheck_path
    interval            = 30
    timeout             = 20
    healthy_threshold   = 3
    unhealthy_threshold = 4
    matcher             = 200
  }
  tags = {
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "green" {
  name        = "${local.resources_name}-green"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    protocol            = "HTTP"
    path                = var.lb_healthcheck_path
    interval            = 30
    timeout             = 20
    healthy_threshold   = 3
    unhealthy_threshold = 4
    matcher             = 200
  }
  tags = {
    Terraform = "true"
  }
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn   = var.ssl_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

resource "aws_lb_listener_rule" "web_https_default" {
  listener_arn = aws_lb_listener.web_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  lifecycle {
    ignore_changes = [
      action
    ]
  }
}
resource "aws_lb_listener_rule" "web_https_maintenance" {
  listener_arn = aws_lb_listener.web_https.arn
  priority     = 101

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      status_code  = "503"
      message_body = "MAINTAINANCE MODE"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

