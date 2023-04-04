variable "env" {}
variable "service" {}

data "aws_region" "self" {}
data "aws_caller_identity" "self" {}
