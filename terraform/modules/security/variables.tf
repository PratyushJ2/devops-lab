variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH in — set this to YOUR_IP/32, never 0.0.0.0/0"
  type        = string
}

variable "vpc_cidr" {
  description = "The VPC's CIDR block, used to scope internal-only ports (Prometheus, Grafana, node_exporter)"
  type        = string
}