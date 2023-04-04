variable "env" {}
variable "service" {}
variable "container_name" {}
variable "cluster_name" {}

variable "vpc_id" {}
variable "subnet_1a_id" {}
variable "subnet_1c_id" {}
variable "alb_target_group_arn" {}
variable "alb_sg_id" {}

data "aws_caller_identity" "self" {}