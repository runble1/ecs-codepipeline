########
# S3 (Dockerイメージの取得)
########
resource "aws_s3_bucket" "default" {
  bucket = "${var.env}-${var.service}-${data.aws_caller_identity.self.account_id}"
}

resource "aws_s3_bucket_lifecycle_configuration" "default" {
  rule {
    id     = "${var.env}-${var.service}-lifecycle-rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }

  bucket = aws_s3_bucket.default.id
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.self.name}.s3"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : ["*"],#S3に絞る
        Effect : "Allow",
        Resource : "*",
        Principal : "*"
      }
    ]
  })

  tags = {
    Environment = "${var.env}-${var.service}-s3endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "private_1a_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
  route_table_id  = aws_route_table.private_1a.id
}

resource "aws_vpc_endpoint_route_table_association" "private_1c_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
  route_table_id  = aws_route_table.private_1c.id
}

########
# ecr api (aws ecr get-login-password) 
########
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.self.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Environment = "${var.env}-${var.service}-ecr.api.endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "ecr_api_private_1a" {
  vpc_endpoint_id = aws_vpc_endpoint.ecr_api.id
  subnet_id       = aws_subnet.private_1a.id
}

resource "aws_vpc_endpoint_subnet_association" "ecr_api_private_1c" {
  vpc_endpoint_id = aws_vpc_endpoint.ecr_api.id
  subnet_id       = aws_subnet.private_1c.id
}

########
# ecr dkr (docker image push)
########
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.self.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Environment = "${var.env}-${var.service}-ecr.dkr.endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "ecr_dkr_private_1a" {
  vpc_endpoint_id = aws_vpc_endpoint.ecr_dkr.id
  subnet_id       = aws_subnet.private_1a.id
}

resource "aws_vpc_endpoint_subnet_association" "ecr_dkr_private_1c" {
  vpc_endpoint_id = aws_vpc_endpoint.ecr_dkr.id
  subnet_id       = aws_subnet.private_1c.id
}

########
# cloudwatch
########
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.self.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Environment = "${var.env}-${var.service}-logs.endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "logs_private_1a" {
  vpc_endpoint_id = aws_vpc_endpoint.logs.id
  subnet_id       = aws_subnet.private_1a.id
}

resource "aws_vpc_endpoint_subnet_association" "logs_private_1c" {
  vpc_endpoint_id = aws_vpc_endpoint.logs.id
  subnet_id       = aws_subnet.private_1c.id
}

########
# Secrets Manager
########
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.self.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Environment = "${var.env}-${var.service}-secretsmanager.endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "secretsmanager_private_1a" {
  vpc_endpoint_id = aws_vpc_endpoint.secretsmanager.id
  subnet_id       = aws_subnet.private_1a.id
}

resource "aws_vpc_endpoint_subnet_association" "secretsmanager_private_1c" {
  vpc_endpoint_id = aws_vpc_endpoint.secretsmanager.id
  subnet_id       = aws_subnet.private_1c.id
}

########
# SSM for Parameter Store
########
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.self.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  tags = {
    Environment = "${var.env}-${var.service}-ssm.endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "ssm_private_1a" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm.id
  subnet_id       = aws_subnet.private_1a.id
}

resource "aws_vpc_endpoint_subnet_association" "ssm_private_1c" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm.id
  subnet_id       = aws_subnet.private_1c.id
}

#########################
# security group
#########################
resource "aws_security_group" "vpc_endpoint" {
  name   = "${var.env}-${var.service}-vpc-endpoint-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #絞るとAWSサービスへアクセスできない？
  }

  tags = {
    Name = "${var.env}-${var.service}-vpc-endpoint-sg"
  }
}
