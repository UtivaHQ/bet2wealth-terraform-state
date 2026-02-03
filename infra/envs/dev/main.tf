# Provider
provider "aws" {
  region = var.region
}

# Modules
module "vpc" {
  source = "../../modules/vpc"
  env    = var.env
  region = var.region
}

module "alb" {
  source            = "../../modules/alb"
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnets    = module.vpc.public_subnets
  domain_name       = var.domain_name
  health_check_path = var.health_check_path
}

module "ecr" {
  source = "../../modules/ecr"
  env    = var.env
}

module "iam" {
  source                                    = "../../modules/iam"
  env                                       = var.env
  region                                    = var.region
  create_github_oidc_provider               = var.create_github_oidc_provider
  create_github_actions_deploy_role         = var.create_github_actions_deploy_role
  github_repo                               = var.github_repo
  github_branches                           = var.github_branches
  github_actions_deploy_attach_admin_policy = var.github_actions_deploy_attach_admin_policy

}

module "ecs" {
  source = "../../modules/ecs"

  env                   = var.env
  region                = var.region
  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.private_subnets
  target_group_arn      = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id

  image_url      = var.backend_image
  container_port = var.backend_container_port

  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  container_environment = var.container_environment
  container_secrets     = var.container_secrets
}

module "redis" {
  source                = "../../modules/redis"
  env                   = var.env
  vpc_id                = module.vpc.vpc_id
  private_subnets       = module.vpc.private_subnets
  ecs_security_group_id = module.ecs.ecs_security_group_id
}

# Outputs
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "redis_endpoint" {
  value = module.redis.redis_primary_endpoint
}

output "github_actions_deploy_role_arn" {
  value = module.iam.github_actions_deploy_role_arn
}

output "cert_validation_records" {
  value = module.alb.cert_validation_records
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
