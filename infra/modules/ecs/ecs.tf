####################################################
# ECS Cluster
####################################################
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

####################################################
# ECS Task
####################################################
data "aws_ecs_task_definition" "task" {
  task_definition = aws_ecs_task_definition.task.family
}

resource "aws_ecs_task_definition" "task" {
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "${var.container_name}-task-definition"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  #skip_destroy = true
  
  container_definitions = jsonencode([{
    name      = "${var.service}"
    image = "${data.aws_ssm_parameter.image_name.value}"
    #image = "${data.aws_ssm_parameter.image_name.value}:${data.aws_ssm_parameter.image_tag.value}"
    essential = true
    cpu       = 11
    memory    = 256
    portMappings = [
      {
        containerPort = 3000
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.service}"
        "awslogs-region"        = "ap-northeast-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
    healthCheck = {
      command = [
        "CMD-SHELL",
        "wget -q -O - http://localhost:3000/api/healthcheck || exit 1"
      ]
      interval    = 5
      retries     = 3
      startPeriod = 60
      timeout     = 5
    }
  }])

  runtime_platform {
    operating_system_family = "LINUX"
    #cpu_architecture        = "ARM64" // M1でビルドした用
    cpu_architecture = "X86_64" // codebuildでやった場合
  }
}

####################################################
# ECS Service
####################################################
resource "aws_ecs_service" "service" {
  name             = "${var.container_name}-service"
  cluster          = aws_ecs_cluster.cluster.arn
  #task_definition  = aws_ecs_task_definition.task.arn
  task_definition  = data.aws_ecs_task_definition.task.arn
  desired_count    = 0 # Github Actions で管理
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  # 追加: サービスが更新されるたびに新しいデプロイメントを強制
  #force_new_deployment = true

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs.id]
    subnets          = [var.subnet_1a_id, var.subnet_1c_id]
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.container_name
    container_port   = 3000
  }

  ## デプロイ毎にタスク定義が更新されるため、リソース初回作成時を除き変更を無視
  lifecycle {
    ignore_changes = [desired_count]
  }
}

####################################################
# IAM for ECS
####################################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.container_name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "amazon_ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution" {
  name = "${var.container_name}-task-execution-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}

####################################################
# Security Group
####################################################
resource "aws_security_group" "ecs" {
  name        = "${var.container_name}-sg-ecs"
  description = "${var.container_name}-sg-ecs"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.service}-ecs-sg"
  }
}

resource "aws_security_group_rule" "ecs_from_alb" {
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  type                     = "ingress"
  source_security_group_id = var.alb_sg_id
}

resource "aws_security_group_rule" "ecs_allow_ecr" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs.id
  type              = "ingress"
  cidr_blocks       = ["52.199.127.192/27", "52.199.127.224/27"] #ECR用
}

####################################################
# Systems Manger Parameter Store
####################################################
data "aws_ssm_parameter" "image_name" {
  name = "/${var.service}/image_name"
}


/*
resource "aws_ssm_parameter" "image_name" {
  name  = "/${var.service}/image_name"
  type  = "String"
  value = "${data.aws_caller_identity.self.account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${var.service}:v0.1"

  # value が変更されても Terraform で差分が発生しない
  lifecycle {
    ignore_changes = [value]
  }
}*/

