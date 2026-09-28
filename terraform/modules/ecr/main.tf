resource "aws_ecr_repository" "app" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE" # lets you push "latest" repeatedly, simplest for a lab

  image_scanning_configuration {
    scan_on_push = true # free vulnerability scanning on every push — worth having on by default
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecr"
    Environment = var.environment
  }
}

# Without this, untagged/orphaned image layers (left behind every time
# you push a new "latest") accumulate forever and slowly cost more.
# This expires untagged images after 7 days; tagged images are never
# touched by this rule.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}