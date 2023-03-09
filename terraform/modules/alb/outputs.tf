
output "lb_listener_arns" {
  description = "ARN of the application load balancer listner"
  value       = [aws_lb_listener.web_https.arn]
}

output "target_group_blue_arn" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
  value       = aws_lb_target_group.blue.arn
  depends_on = [ // Needs to specify dependencies. If not terraform apply fails sometimes.
    aws_lb_listener.web_http,
    aws_lb_listener.web_https
  ]
}

output "target_group_blue_name" {
  description = "Name of the target groups. Useful for passing to your Auto Scaling group."
  value       = aws_lb_target_group.blue.name
}

output "target_group_green_name" {
  description = "Name of the target groups. Useful for passing to your Auto Scaling group."
  value       = aws_lb_target_group.green.name
}

output "dns_name" {
  description = "DNS name of alb"
  value       = aws_lb.web.dns_name
}

output "zone_id" {
  description = "Zone id of alb"
  value       = aws_lb.web.zone_id
}

output "target_group_green_arn_suffix" {
  description = "Target group ARN suffix"
  value       = aws_lb_target_group.green.arn_suffix
}

output "target_group_blue_arn_suffix" {
  description = "Target group ARN suffix"
  value       = aws_lb_target_group.blue.arn_suffix
}

output "web_arn_suffix" {
  description = "Target group ARN suffix"
  value       = aws_lb.web.arn_suffix

}

output "web_arn" {
  description = "ARN of alb"
  value       = aws_lb.web.arn
}
