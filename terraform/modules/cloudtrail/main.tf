resource "aws_cloudtrail" "cloudtrail" {
  name                          = var.name
  s3_bucket_name                = var.cloudtrail_bucket_id
  include_global_service_events = false
}
