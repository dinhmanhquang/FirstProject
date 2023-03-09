output "cluster_address" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}
output "port" {
  value = aws_elasticache_cluster.redis.cache_nodes.0.port
}

output "elasticache_member_clusters" {
  value = tolist(aws_elasticache_replication_group.this.member_clusters)
}

output "aws_elasticache_replication_group" {
  value = aws_elasticache_replication_group.this
}

output "name" {
  value = aws_elasticache_parameter_group.this.name
}
