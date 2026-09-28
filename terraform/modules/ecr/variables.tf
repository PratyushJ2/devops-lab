variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "repository_name" {
  description = "Name of the ECR repository (this becomes part of the image URI)"
  type        = string
  default     = "devops-lab-app"
}