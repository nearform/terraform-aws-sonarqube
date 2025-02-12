################################################################################
# Commons
################################################################################
data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

################################################################################
# Elastic Container Registry
################################################################################
resource "aws_ecr_repository" "sonarqube" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"
  tags                 = var.tags
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
}

# Authenticate to ECR, pull the public image from Docker Hub, tag it, and push to ECR
resource "null_resource" "sonar_image_pull_tag_push" {
  depends_on = [aws_ecr_repository.sonarqube]

  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.sonarqube.repository_url}
      docker pull sonarqube:${var.sonar_image_tag}
      docker tag sonarqube:${var.sonar_image_tag} ${aws_ecr_repository.sonarqube.repository_url}:${var.sonar_image_tag}
      docker push ${aws_ecr_repository.sonarqube.repository_url}:${var.sonar_image_tag}
    EOT
  }
}

################################################################################
# RDS instance
################################################################################
resource "aws_db_instance" "sonarqube" {
  identifier              = var.sonar_db_server
  allocated_storage       = 20
  max_allocated_storage   = 0
  storage_type            = var.sonar_db_storage_type
  instance_class          = var.sonar_db_instance_class
  engine                  = "postgres"
  engine_version          = "16"
  db_name                 = var.sonar_db_name
  username                = var.sonar_db_user
  password                = random_password.sonarqube_rds_password.result
  publicly_accessible     = false
  db_subnet_group_name    = var.database_subnet_group_name
  vpc_security_group_ids  = [aws_security_group.sonarqube_rds_sg.id]
  multi_az                = false
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.sonarqube.arn
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = true
  tags                    = var.tags
}

# KMS Key for RDS encryption at rest
resource "aws_kms_key" "sonarqube" {
  description         = "KMS key for RDS encryption"
  enable_key_rotation = true
  tags                = var.tags
}

# RDS Security Group
resource "aws_security_group" "sonarqube_rds_sg" {
  name        = "${var.name}rdssg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

################################################################################
# RDS credentials
################################################################################
resource "random_password" "sonarqube_rds_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "sonardb_credentials" {
  name        = "sonardb-credentials"
  description = "SonarQube Database Credentials"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "sonardb_credentials" {
  secret_id     = aws_secretsmanager_secret.sonardb_credentials.id
  secret_string = <<EOF
{
  "username": "${aws_db_instance.sonarqube.username}",
  "password": "${random_password.sonarqube_rds_password.result}",
  "engine": "${aws_db_instance.sonarqube.engine}",
  "host": "${aws_db_instance.sonarqube.address}",
  "port": ${aws_db_instance.sonarqube.port},
  "dbName": "${aws_db_instance.sonarqube.db_name}",
  "dbServerIdentifier": "${aws_db_instance.sonarqube.id}"
}
EOF
}

################################################################################
# EFS volumes
################################################################################
resource "aws_efs_file_system" "sonarqube_data" {
  encrypted = true
  tags      = merge(var.tags, { "Name" = "SonarQube Data" })
}

resource "aws_efs_file_system" "sonarqube_extensions" {
  encrypted = false
  tags      = merge(var.tags, { "Name" = "SonarQube Extensions" })
}

resource "aws_efs_mount_target" "sonarqube_data" {
  file_system_id  = aws_efs_file_system.sonarqube_data.id
  subnet_id       = var.private_subnets[0]
  security_groups = [aws_security_group.sonarqube_efs_sg.id]
}

resource "aws_efs_mount_target" "sonarqube_extensions" {
  file_system_id  = aws_efs_file_system.sonarqube_extensions.id
  subnet_id       = var.private_subnets[0]
  security_groups = [aws_security_group.sonarqube_efs_sg.id]
}

################################################################################
# EFS security groups
################################################################################
resource "aws_security_group" "sonarqube_efs_sg" {
  name        = "${var.name}efssg"
  description = "Security group for SonarQube EFS mount targets"
  vpc_id      = var.vpc_id
  tags        = var.tags
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube_ecs_sg.id]
  }
}

################################################################################
# Fargate cluster
################################################################################
resource "aws_ecs_cluster" "sonarqube" {
  name = var.name
  tags = var.tags
}

################################################################################
# Fargate task definition
################################################################################
resource "aws_ecs_task_definition" "sonarqube" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "6144"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  container_definitions = jsonencode([
    {
      name  = var.sonar_container_name,
      image = "${aws_ecr_repository.sonarqube.repository_url}:${var.sonar_image_tag}",
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }
      ],
      mountPoints = [
        {
          sourceVolume  = "sonar-data"
          containerPath = "/opt/sonarqube/data"
          readOnly      = false
        },
        {
          sourceVolume  = "sonar-extensions"
          containerPath = "/opt/sonarqube/extensions"
          readOnly      = false
        }
      ],
      environment = [
        { name = "SONAR_JDBC_URL", value = "jdbc:postgresql://${aws_db_instance.sonarqube.endpoint}/${var.sonar_db_name}" },
        { name = "SONAR_JDBC_USERNAME", value = var.sonar_db_user },
        { name = "SONAR_SEARCH_JAVAADDITIONALOPTS", value = "-Dnode.store.allow_mmap=false,-Ddiscovery.type=single-node" },
        { name = "SONAR_WEB_CONTEXT", value = "/" },
        # { name = "SONAR_WEB_JAVAADDITIONALOPTS", value = "-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-1.22.0.jar=web" },
        # { name = "SONAR_CE_JAVAADDITIONALOPTS", value = "-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-1.22.0.jar=ce" }
      ]
      secrets = [
        { name = "SONAR_JDBC_PASSWORD", valueFrom = random_password.sonarqube_rds_password.result },
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/${var.name}"
          awslogs-region        = local.region
          awslogs-stream-prefix = "ecs"
        }
      },
      ulimits = [
        {
          name      = "nofile",
          softLimit = 65535,
          hardLimit = 65535
        }
      ]
    }
  ])
  volume {
    name = "sonar-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.sonarqube_data.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }
  volume {
    name = "sonar-extensions"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.sonarqube_extensions.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }
}

# IAM Role for ECS Task Exec Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}ecstaskexecrole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" : "${local.account_id}"
          }
        }
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

# Attach policy to the IAM role
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.name}ecstaskpolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

################################################################################
# Fargate service
################################################################################
resource "aws_ecs_service" "sonarqube" {
  name                   = var.name
  cluster                = aws_ecs_cluster.sonarqube.id
  task_definition        = aws_ecs_task_definition.sonarqube.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true
  tags                   = var.tags
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.sonarqube_ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.sonarqube.arn
    container_name   = var.sonar_container_name
    container_port   = var.sonar_port
  }
}

################################################################################
# Fargate security groups
################################################################################
resource "aws_security_group" "sonarqube_ecs_sg" {
  name        = "${var.name}ecssg"
  description = "Security group for SonarQube ECS instance"
  vpc_id      = var.vpc_id
  tags        = var.tags
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = var.sonar_port
    to_port         = var.sonar_port
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube_alb_sg.id]
  }
}

################################################################################
# Application Load Balancer
################################################################################
resource "aws_lb" "sonarqube" {
  name                       = "${var.name}alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.public_subnets
  security_groups            = [aws_security_group.sonarqube_alb_sg.id]
  enable_deletion_protection = true
  drop_invalid_header_fields = true
  tags                       = var.tags
}

# ALB Security Group
resource "aws_security_group" "sonarqube_alb_sg" {
  name        = "${var.name}albsg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  tags        = var.tags
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
  name        = "${var.name}tg"
  port        = var.sonar_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  tags        = var.tags
  health_check {
    path                = "/api/system/status"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  depends_on = [aws_ecs_task_definition.sonarqube]
}

# ALB Listener
resource "aws_lb_listener" "sonarqube_http_listener" {
  load_balancer_arn = aws_lb.sonarqube.arn
  port              = "80"
  protocol          = "HTTP"
  tags              = var.tags
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

################################################################################
# Cloudwatch Log Group
################################################################################
resource "aws_cloudwatch_log_group" "sonarqube_cloudwatch_lg" {
  name              = "/aws/ecs/${var.name}"
  retention_in_days = 90
  tags              = var.tags
}
