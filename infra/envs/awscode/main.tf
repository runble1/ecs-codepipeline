locals {
  service = "nextjs-awscode"
}

module "ecr" {
  source        = "../../modules/ecr"
  name          = local.service
  holding_count = 5
}

module "codecommit" {
  source          = "../../modules/codecommit"
  repository_name = local.service
}

module "network" {
  source  = "../../modules/network"
  env     = var.env
  service = local.service
}

module "alb" {
  source       = "../../modules/alb"
  env          = var.env
  service      = local.service
  vpc_id       = module.network.vpc_id
  subnet_1a_id = module.network.subnet_public_1a_id
  subnet_1c_id = module.network.subnet_public_1c_id
}

module "ecs" {
  source               = "../../modules/ecs"
  cluster_name         = "next-cluster"
  container_name       = local.service
  vpc_id               = module.network.vpc_id
  subnet_1a_id         = module.network.subnet_private_1a_id
  subnet_1c_id         = module.network.subnet_private_1c_id
  alb_target_group_arn = module.alb.target_group_arn
  alb_sg_id            = module.alb.alb_sg_id
}

/*
module "codepipeline" {
  source                      = "../../modules/codepipeline"
  env                         = "dev"
  prefix                      = "nextjs"
  branch_name                 = "main"
  repository_name             = local.repository_name
  repository_id               = module.codecommit.repository_id
  clone_url_http              = module.codecommit.clone_url_http
  codecommit_arn              = module.codecommit.arn
  ecs_cluster_name            = module.ecs.ecs_cluster_name
  ecs_service_name            = module.ecs.ecs_service_name
  container_name              = local.container_name
  alb_arn                     = module.alb.alb_arn
  ecs_cluster_arn             = module.ecs.ecs_cluster_arn
  ecs_service_arn             = module.ecs.ecs_service_arn
  ecs_task_definition_arn     = module.ecs.ecs_task_definition_arn
  ecs_task_execution_role_arn = module.ecs.ecs_task_execution_role_arn
}*/

module "secrets" {
  source = "../../modules/secrets"
}

/*
module "cloudwatch" {
  source       = "../../modules/cloudwatch"
}*/
