locals {
  security_service3 = "inspector"
}
# ====================
# Inspector
# ====================
/*
data "aws_caller_identity" "self" {}

resource "aws_inspector2_enabler" "example" {
  account_ids    = [data.aws_caller_identity.self.account_id]
  resource_types = ["ECR"]
}
*/

# ====================
# EventBridge (CloudWatch Event)
# ====================
# Custom Bus は対応してないため default Bus を利用
resource "aws_cloudwatch_event_rule" "inspector" {
  name           = "${var.name}-${local.security_service3}"
  description    = "Inspector"
  event_bus_name = "default"

  event_pattern = jsonencode({
    "source" : ["aws.inspector2"],
    "detail-type" : ["Inspector2 Finding"]
  })
}

resource "aws_cloudwatch_event_target" "inspector" {
  rule           = aws_cloudwatch_event_rule.inspector.name
  event_bus_name = "default"
  target_id      = "${var.name}-${local.security_service3}-to-sns"
  arn            = aws_sns_topic.inspector.arn
}

resource "aws_cloudwatch_event_permission" "inspector" {
  principal      = data.aws_caller_identity.self.account_id
  statement_id   = "${var.name}-${local.security_service3}-statement"
  event_bus_name = "default"
  action         = "events:PutEvents"
}

# ====================
# SNS
# ====================
resource "aws_sns_topic" "inspector" {
  name = "${var.name}-${local.security_service3}-topic"
}

resource "aws_sns_topic_policy" "inspector" {
  arn = aws_sns_topic.inspector.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "SNS:Publish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Resource = aws_sns_topic.inspector.arn
      }
    ]
  })
}
