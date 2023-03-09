resource "aws_elasticache_parameter_group" "this" {
  name   = var.name
  family = "redis6.x"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}
resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = var.name
  replication_group_description = "Redis for ${var.name} application"
  node_type                     = "cache.t3.micro"
  number_cache_clusters         = var.env == "production" ? 2 : 0
  automatic_failover_enabled    = var.env == "production" ? true : false
  auto_minor_version_upgrade    = false
  engine                        = "redis"
  engine_version                = "6.x"
  parameter_group_name          = aws_elasticache_parameter_group.this.name
  maintenance_window            = "Sat:20:00-Sat:21:00"
  port                          = 6379
  availability_zones            = slice(var.azs, 0, var.env == "production" ? 2 : 1)
  subnet_group_name             = var.elasticache_subnets
  security_group_ids            = var.security_groups
  tags = {
    Terraform   = "true"
    Service     = var.service
    DatadogFlag = var.name
  }
  lifecycle {
    ignore_changes = [
      engine_version,
      tags,
      id,
      number_cache_clusters
    ]
  }
}
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.name
  replication_group_id = aws_elasticache_replication_group.this.id
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
