variable "my_secrets" {
  default = {
    key1 = "secret_value1"
    key2 = "secret_value2"
  }
}

resource "aws_secretsmanager_secret" "aurora" {
  name = "aurora_secrets"
}

resource "aws_secretsmanager_secret_version" "aurora" {
  secret_id     = aws_secretsmanager_secret.aurora.id
  secret_string = jsonencode(var.my_secrets)

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
