variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "public_key_path" {
  description = "Path to your local SSH public key, e.g. ~/.ssh/id_ed25519.pub"
  type        = string
}

variable "root_volume_size" {
  type    = number
  default = 20
}