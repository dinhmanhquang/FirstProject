resource "aws_athena_workgroup" "default" {
  name = "${var.name}_default"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_output_bucket_name}/output/"
    }
  }
}

resource "aws_athena_database" "default" {
  name = "${var.name}_default"
  bucket = var.athena_output_bucket_id
}

resource "aws_athena_named_query" "cloutrail" {
  name      = "${var.name}_cloutrail"
  workgroup = aws_athena_workgroup.default.id
  database  = aws_athena_database.default.name
  query     = templatefile("${path.module}/cloudtrail_table.sql",{cloudtrail_bucket_name = "${var.cloudtrail_bucket_name}",aws_account_id= "${var.aws_account_id}"})
}

resource "aws_athena_named_query" "alb_access_log" {
  name      = "${var.name}_alb_access_log"
  workgroup = aws_athena_workgroup.default.id
  database  = aws_athena_database.default.name
  query     = templatefile("${path.module}/alb_access_table.sql",{access_log_bucket_name = "${var.access_log_bucket_name}",aws_account_id= "${var.aws_account_id}"})
}
