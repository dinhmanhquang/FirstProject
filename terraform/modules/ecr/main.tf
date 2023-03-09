
resource "aws_ecr_repository" "web" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Terraform = "true"
  }
}

resource "aws_ecr_lifecycle_policy" "web_lifecycle_policy" {
  repository = aws_ecr_repository.web.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Remove untaggaed images",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 3
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}