# ====================
# Chatbot
# ====================
resource "awscc_chatbot_slack_channel_configuration" "chatbot" {
  configuration_name = "${var.name}-chatbot"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id

  iam_role_arn       = aws_iam_role.chatbot.arn
  guardrail_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  user_role_required = false

  sns_topic_arns = [
    aws_sns_topic.inspector.arn,
    aws_sns_topic.iam_access_analyzer.arn,
    aws_sns_topic.config_rules.arn
  ]

  logging_level = "ERROR"
}

resource "aws_iam_role" "chatbot" {
  name = "${var.name}-chatbot-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "chatbot.amazonaws.com"
        },
        Effect : "Allow",
      }
    ]
  })
}

resource "aws_iam_policy" "chatbot" {
  name = "${var.name}-chatbot-policy"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish",
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chatbot" {
  policy_arn = aws_iam_policy.chatbot.arn
  role       = aws_iam_role.chatbot.name
  depends_on = [aws_iam_policy.chatbot, aws_iam_role.chatbot]
}
