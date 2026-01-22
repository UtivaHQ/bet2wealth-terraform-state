# ECR Repository for the backend
resource "aws_ecr_repository" "this" {
  name                 = "${var.repository_name}-${var.env}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Terraform = "true"
    Environment = var.env
    Service     = "backend"
  }
}

# ECR Lifecycle Policy for the backend
resource "aws_ecr_lifecycle_policy" "cleanup" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
