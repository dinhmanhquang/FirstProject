module "rds" {
  source                          = "terraform-aws-modules/rds/aws"
  identifier                      = var.name
  engine                          = "postgres"
  engine_version                  = "14.1"
  instance_class                  = var.instance_class
  create_random_password          = false
  allocated_storage               = 10
  db_name                         = var.database_name
  username                        = var.user
  password                        = var.password
  port                            = "5432"
  vpc_security_group_ids          = var.security_groups
  maintenance_window              = "Sat:20:00-Sat:20:30"
  backup_window                   = "11:00-11:30"
  monitoring_interval             = var.env == "production" ? "60" : 0
  monitoring_role_name            = "rds_monitoring_${var.name}"
  create_monitoring_role          = true
  backup_retention_period         = 14
  subnet_ids                      = var.subnets
  db_subnet_group_name            = var.database_subnet_group_name
  major_engine_version            = "14"
  deletion_protection             = var.env == "production"
  allow_major_version_upgrade     = false
  apply_immediately               = false
  publicly_accessible             = false
  delete_automated_backups        = true
  auto_minor_version_upgrade      = false
  multi_az                        = false
  storage_encrypted               = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  family                          = "postgres14"
  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
  tags = {
    Terraform = "true"
  }
}
