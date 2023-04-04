variable "name" {}
variable "slack_workspace_id" {}
variable "slack_channel_id" {}

data "aws_caller_identity" "self" {}