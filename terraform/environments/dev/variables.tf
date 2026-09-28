variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "devops-lab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "ssh_allowed_cidr" {
  description = "YOUR public IP in CIDR form, e.g. 203.0.113.7/32. Find it with: curl -s ifconfig.me"
  type        = string
  # Intentionally no default — you must set this yourself in terraform.tfvars.
}

variable "instance_type" {
  type    = string
  default = "t3.micro" # free-tier eligible
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "ecr_repository_name" {
  type    = string
  default = "devops-lab-app"
}