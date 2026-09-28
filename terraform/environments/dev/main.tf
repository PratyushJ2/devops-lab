module "networking" {
  source = "../../modules/networking"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  availability_zone   = var.availability_zone
}

module "security" {
  source = "../../modules/security"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  vpc_cidr          = var.vpc_cidr
  ssh_allowed_cidr  = var.ssh_allowed_cidr
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "ecr" {
  source = "../../modules/ecr"

  project_name    = var.project_name
  environment     = var.environment
  repository_name = var.ecr_repository_name
}

module "compute" {
  source = "../../modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  instance_type          = var.instance_type
  subnet_id              = module.networking.public_subnet_id
  security_group_id      = module.security.app_sg_id
  instance_profile_name  = module.iam.instance_profile_name
  public_key_path        = var.public_key_path
}