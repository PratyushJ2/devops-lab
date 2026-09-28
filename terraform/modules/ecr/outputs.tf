output "repository_url" {
  description = "Full URI to use as the Docker image reference, e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/devops-lab-app"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.app.arn
}