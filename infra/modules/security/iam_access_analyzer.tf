locals {
  security_service2 = "iam-access-analyzer"
}

# ====================
# IAM Access Analyzer
# ====================
resource "aws_accessanalyzer_analyzer" "iam_access_analyzer" {
  analyzer_name = "${var.name}-iam-access-analyzer-analyzer"
  type          = "ACCOUNT"
}

# ====================
# EventBridge (CloudWatch Event)
# ====================
# Custom Bus は対応してないため default Bus を利用
resource "aws_cloudwatch_event_rule" "iam_access_analyzer" {
  name           = "${var.name}-${local.security_service2}"
  description    = "IAM Access Analyzer Findings"
  event_bus_name = "default"

  event_pattern = jsonencode({
    "source" : ["aws.access-analyzer"],
  })
}

resource "aws_cloudwatch_event_target" "iam_access_analyzer" {
  rule           = aws_cloudwatch_event_rule.iam_access_analyzer.name
  event_bus_name = "default"
  target_id      = "${var.name}-${local.security_service2}-to-sns"
  arn            = aws_sns_topic.iam_access_analyzer.arn
}

resource "aws_cloudwatch_event_permission" "iam_access_analyzer" {
  principal      = data.aws_caller_identity.self.account_id
  statement_id   = "${var.name}-${local.security_service2}-statement"
  event_bus_name = "default"
  action         = "events:PutEvents"
}

# ====================
# SNS
# ====================
resource "aws_sns_topic" "iam_access_analyzer" {
  name = "${var.name}-${local.security_service2}-topic"
}

resource "aws_sns_topic_policy" "iam_access_analyzer" {
  arn = aws_sns_topic.iam_access_analyzer.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "SNS:Publish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Resource = aws_sns_topic.iam_access_analyzer.arn
      }
    ]
  })
}



# ====================
# Test
# ====================
/*
resource "aws_s3_bucket" "test_bucket" {
  bucket = "test-test-test-test-${data.aws_caller_identity.self.account_id}"
}

resource "aws_s3_bucket_policy" "test_bucket_policy" {
  bucket = aws_s3_bucket.test_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:GetObject"
        Effect = "Allow"
        Principal = "*"
        Resource = "${aws_s3_bucket.test_bucket.arn}/*"
      }
    ]
  })
}*/
