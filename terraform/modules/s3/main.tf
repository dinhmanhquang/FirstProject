module "access_log_s3_bucket" {
  source                         = "terraform-aws-modules/s3-bucket/aws"
  version                        = "3.5.0"
  bucket                         = "${var.name}-access-log"
  acl                            = "log-delivery-write"
  force_destroy                  = true
  attach_elb_log_delivery_policy = true
  tags = {
    Terraform = "true"
  }
  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]
}

module "pipeline_artifact_s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.5.0"
  bucket        = "${var.name}-pipeline-artifact"
  acl           = "private"
  force_destroy = true
  tags = {
    Terraform = "true"
  }
  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]
}

module "vpc_flow_s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.5.0"
  bucket        = "${var.name}-vpc-flow-log"
  acl           = "private"
  force_destroy = true
  tags = {
    Terraform = "true"
  }
  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]
}

module "cloudwatch_log_groups" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.5.0"
  bucket        = "${var.name}-cloudwatch-log-groups"
  acl           = "private"
  force_destroy = true
  tags = {
    Terraform = "true"
  }
  attach_policy = true
  policy        = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Principal": {
            "Service": "logs.ap-northeast-1.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "arn:aws:s3:::${var.name}-cloudwatch-log-groups"
    },
    {
        "Effect": "Allow",
        "Principal": {
            "Service": "logs.ap-northeast-1.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${var.name}-cloudwatch-log-groups/*",
        "Condition": {
            "StringEquals": {
                "s3:x-amz-acl": "bucket-owner-full-control"
            }
        }
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "exec_ssh" {
  bucket = "${var.name}-ecs-exec"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Terraform = "true"
  }
  lifecycle_rule {
    id      = "log"
    enabled = true
    tags = {
      rule      = "log"
      autoclean = "true"
    }
    expiration {
      days = 365
    }
  }
}

# CloudTrail
module "cloutrail_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.5.0"
  bucket        = "${var.name}-cloudtrail"
  acl           = "private"
  force_destroy = true
  tags = {
    Terraform = "true"
  }

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]

  attach_policy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.name}-cloudtrail"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.name}-cloudtrail/AWSLogs/${var.aws_account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF
}

module "athena_output_s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.5.0"
  bucket        = "${var.name}-athena-output"
  acl           = "private"
  force_destroy = true
  tags = {
    Terraform = "true"
  }

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]
}

# Cloudwatch Exporter
module "rds_bucket_name" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.5.0"
  bucket        = "${var.name}-rds"
  acl           = "private"
  force_destroy = true
  tags = {
    Terraform = "true"
  }

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]
  attach_policy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
          "Action": "s3:GetBucketAcl",
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.name}-rds",
          "Principal": { "Service": "logs.ap-northeast-1.amazonaws.com" }
      },
      {
          "Action": "s3:PutObject" ,
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.name}-rds/*",
          "Condition": { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } },
          "Principal": { "Service": "logs.ap-northeast-1.amazonaws.com" }
      }
    ]
}
  EOF
}
module "codebuild_bucket_name" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.5.0"
  bucket        = "${var.name}-codebuild"
  acl           = "private"
  force_destroy = true
  tags = {
    Terraform = "true"
  }

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]
  attach_policy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
          "Action": "s3:GetBucketAcl",
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.name}-codebuild",
          "Principal": { "Service": "logs.ap-northeast-1.amazonaws.com" }
      },
      {
          "Action": "s3:PutObject" ,
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.name}-codebuild/*",
          "Condition": { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } },
          "Principal": { "Service": "logs.ap-northeast-1.amazonaws.com" }
      }
    ]
}
  EOF
}
module "ecs_web_bucket_name" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "3.5.0"
  bucket        = "${var.name}-ecs-web"
  acl           = "private"
  force_destroy = true
  tags = {
    Terraform = "true"
  }

  lifecycle_rule = [
    {
      id      = "log"
      enabled = true

      expiration = {
        days = 365
      }
    }
  ]
  attach_policy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
          "Action": "s3:GetBucketAcl",
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.name}-ecs-web",
          "Principal": { "Service": "logs.ap-northeast-1.amazonaws.com" }
      },
      {
          "Action": "s3:PutObject" ,
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.name}-ecs-web/*",
          "Condition": { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } },
          "Principal": { "Service": "logs.ap-northeast-1.amazonaws.com" }
      }
    ]
}
  EOF
}

#For S3 bucket related to code
module "s3_bucket" {
  source                  = "terraform-aws-modules/s3-bucket/aws"
  version                 = "3.5.0"
  bucket                  = var.bucket_name
  acl                     = "private"
  force_destroy           = true
  # block_public_acls       = true
  # block_public_policy     = true
  # ignore_public_acls      = true
  # restrict_public_buckets = true

  tags = {
    Terraform = "true"
  }
  attach_policy = true
  policy        = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid": "Stmt1526330824446",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.s3_user_arn}"
      },
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::${var.bucket_name}"

    }
  ]
}
EOF
}