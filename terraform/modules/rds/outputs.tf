
output "db_endpoint" {
  description = "Db endpoint"
  value       = module.rds.db_instance_endpoint
}

output "id" {
  description = "id of the database"
  value       = module.rds.db_instance_id
}
