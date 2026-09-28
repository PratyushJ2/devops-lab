output "instance_public_ip" {
  value = module.compute.public_ip
}

output "instance_public_dns" {
  value = module.compute.public_dns
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "ssh_command" {
  description = "Quick copy-paste to SSH in once the instance is up"
  value       = "ssh ubuntu@${module.compute.public_ip}"
}

output "ecr_repository_url" {
  description = "Full image URL to use for docker build/tag/push, e.g. this value + ':latest'"
  value       = module.ecr.repository_url
}