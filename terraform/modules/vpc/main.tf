module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  version             = "v3.0.0"
  name                = var.name
  cidr                = var.cidr
  azs                 = var.azs
  public_subnets      = var.public_subnets
  database_subnets    = var.database_subnets
  elasticache_subnets = var.elasticache_subnets
  enable_nat_gateway  = false
  single_nat_gateway  = false
  tags = {
    Terraform = "true"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  route_table_ids   = module.vpc.public_route_table_ids
}

resource "aws_flow_log" "s3" {
  log_destination      = var.aws_s3_bucket_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
}
