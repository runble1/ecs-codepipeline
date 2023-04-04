variable "env" {}
variable "prefix" {}
variable "repository_name" {}
variable "branch_name" {}

variable "repository_id" {}
variable "clone_url_http" {}
variable "codecommit_arn" {}

variable "ecs_cluster_name" {}
variable "ecs_service_name" {}

variable "container_name" {}
variable "alb_arn" {}

variable "ecs_cluster_arn" {}
variable "ecs_service_arn" {}
variable "ecs_task_definition_arn" {}
variable "ecs_task_execution_role_arn" {}

data "aws_caller_identity" "self" {}
data "aws_region" "self" {}

