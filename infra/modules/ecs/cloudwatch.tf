####################################################
# ECS Task Container Log Groups
####################################################
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.service}"
  retention_in_days = 30
}
