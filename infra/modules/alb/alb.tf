# ====================
# ALB
# ====================
resource "aws_lb" "for_webserver" {
  name               = "${var.env}-${var.service}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    var.subnet_1a_id,
    var.subnet_1c_id
  ]

  drop_invalid_header_fields = true

  tags = {
    Name = "${var.env}-${var.service}-ig"
  }
}

# ====================
# Target Group
# ====================
resource "aws_lb_target_group" "for_webserver" {
  name   = "${var.env}-${var.service}-tg"
  vpc_id = var.vpc_id

  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"

  # コンテナへの死活監視設定
  health_check {
    path = "/api/healthcheck"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.env}-${var.service}-ig"
  }
}

# ====================
# Listener
# ====================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.for_webserver.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.for_webserver.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}
/*
resource "aws_lb_listener_rule" "forward" {
  listener_arn = aws_lb_listener.for_webserver.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.for_webserver.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}*/

# ====================
# Security Group
# ====================
resource "aws_security_group" "alb" {
  name        = "${var.env}-${var.service}-alb-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.service}-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_http" {
  from_port         = 80 //80から
  to_port           = 80 //80までアクセス許可
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}