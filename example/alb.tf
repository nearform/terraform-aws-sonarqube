# Application Load Balancer
resource "aws_lb" "alb" {
  name                       = "${var.environment}${var.project_name}alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.public_subnets
  security_groups            = [aws_security_group.alb_sg.id]
  enable_deletion_protection = true
  drop_invalid_header_fields = true
  tags                       = local.common_tags
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}${var.project_name}albsg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Allow HTTP traffic"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Allow HTTPS traffic"
      from_port        = 443
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 443
    }
  ]
}

# ALB Target Group
resource "aws_lb_target_group" "sonarqube" {
  name        = "${var.environment}${var.project_name}tg"
  port        = var.sonar_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  tags        = local.common_tags
  health_check {
    path                = "/sonar/api/system/status"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  depends_on = [aws_ecs_task_definition.sonarqube]
}

# ALB Listener
resource "aws_lb_listener" "backend_alb_http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  tags              = local.common_tags
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube.arn
    forward {
      target_group {
        arn    = aws_lb_target_group.sonarqube.arn
        weight = 1
      }
    }
  }
}
