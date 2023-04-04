resource "aws_cloudwatch_log_group" "dockle_check" {
  name              = "/aws/codebuild/${var.prefix}-${var.env}-dockle-check"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "secrets_check" {
  name              = "/aws/codebuild/${var.prefix}-${var.env}-secrets-check"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "trivy_check" {
  name              = "/aws/codebuild/${var.prefix}-${var.env}-trivy-check3"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "build" {
  name              = "/aws/codebuild/${var.prefix}-${var.env}-build"
  retention_in_days = 30
}

resource "aws_cloudwatch_event_rule" "this" {
  name = "${var.prefix}-${var.env}-repo-state-change"
  event_pattern = jsonencode({
    detail-type : [
      "CodeCommit Repository State Change"
    ],
    resources : [
      var.codecommit_arn
    ],
    source : [
      "aws.codecommit"
    ],
    detail : {
      event : [
        "referenceCreated",
        "referenceUpdated"
      ],
      referenceName : [
        "${var.branch_name}"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "this" {
  rule     = aws_cloudwatch_event_rule.this.id
  arn      = aws_codepipeline.this.arn
  role_arn = aws_iam_role.cloudwatch_events.arn
}
