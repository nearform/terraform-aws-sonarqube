# SonarQube
data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

resource "aws_ecr_repository" "sonarqube_ecr" {
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

resource "random_password" "sonarqube_rds_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "sonarqube" {
  identifier              = var.sonar_db_server
  allocated_storage       = 20
  max_allocated_storage   = 0
  storage_type            = "gp2"
  instance_class          = "db.t4g.micro"
  engine                  = "postgres"
  engine_version          = "16"
  db_name                 = var.sonar_db_name
  username                = var.sonar_db_user
  password                = random_password.sonarqube_rds_password[0].result
  publicly_accessible     = false
  db_subnet_group_name    = var.database_subnet_group_name
  vpc_security_group_ids  = [aws_security_group.pgsql_sg.id]
  multi_az                = false
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds_key.arn
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = true
  tags                    = var.tags
}

resource "aws_efs_file_system" "sonarqube_data" {
  encrypted = true
  tags      = merge(var.tags, { "Name" = "SonarQube Data" })
}

resource "aws_efs_file_system" "sonarqube_extensions" {
  encrypted = false
  tags      = merge(var.tags, { "Name" = "SonarQube Extensions" })
}

resource "aws_efs_mount_target" "sonarqube_data" {
  file_system_id  = aws_efs_file_system.sonarqube_data[0].id
  subnet_id       = var.private_subnets[0]
  security_groups = [aws_security_group.sonarqube_efs_sg[0].id]
}

resource "aws_efs_mount_target" "sonarqube_extensions" {
  file_system_id  = aws_efs_file_system.sonarqube_extensions[0].id
  subnet_id       = var.private_subnets[0]
  security_groups = [aws_security_group.sonarqube_efs_sg[0].id]
}

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
      image = "${aws_ecr_repository.sonarqube_ecr[0].repository_url}:10.7.0-community",
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
        { name = "SONAR_JDBC_URL", value = "jdbc:postgresql://${aws_db_instance.sonarqube[0].endpoint}/${var.sonar_db_name}" },
        { name = "SONAR_JDBC_USERNAME", value = var.sonar_db_user },
        { name = "SONAR_SEARCH_JAVAADDITIONALOPTS", value = "-Dnode.store.allow_mmap=false,-Ddiscovery.type=single-node" },
        { name = "SONAR_WEB_CONTEXT", value = "/sonar" },
        { name = "SONAR_WEB_JAVAADDITIONALOPTS", value = "-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-1.22.0.jar=web" },
        { name = "SONAR_CE_JAVAADDITIONALOPTS", value = "-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-1.22.0.jar=ce" }
      ]
      secrets = [
        { name = "SONAR_JDBC_PASSWORD", valueFrom = "${aws_secretsmanager_secret_version.sonardb_credentials[0].arn}:password::" },
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
      file_system_id     = aws_efs_file_system.sonarqube_data[0].id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }
  volume {
    name = "sonar-extensions"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.sonarqube_extensions[0].id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }
}

resource "aws_ecs_service" "sonarqube" {
  name                   = var.name
  cluster                = aws_ecs_cluster.backend_ecs_cluster.id
  task_definition        = aws_ecs_task_definition.sonarqube[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true
  tags                   = var.tags
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.sonarqube_ecs_sg[0].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.sonarqube[0].arn
    container_name   = var.sonar_container_name
    container_port   = var.sonar_port
  }
}

# resource "aws_lb_target_group" "sonarqube" {
#   name        = var.name
#   port        = var.sonar_port
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "ip"
#   tags        = var.tags
#   health_check {
#     path                = "/sonar/api/system/status"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 5
#     unhealthy_threshold = 2
#   }
#   depends_on = [aws_ecs_task_definition.sonarqube]
# }

# resource "aws_lb_listener_rule" "sonarqube" {
#   listener_arn = aws_lb_listener.backend_alb_https_listener.arn
#   priority     = 100
#   tags         = merge(var.tags, { "Name" = "SonarQube" })
#   action {
#     type = "forward"
#     forward {
#       target_group {
#         arn = aws_lb_target_group.sonarqube[0].arn
#       }
#       stickiness {
#         duration = 600
#         enabled  = true
#       }
#     }
#   }
#   condition {
#     path_pattern {
#       values = ["/sonar/*"]
#     }
#   }
# }

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
    security_groups = [aws_security_group.alb_sg.id]
  }
}

resource "aws_security_group" "sonarqube_efs_sg" {
  name        = "${var.name}eefssg"
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
    security_groups = [aws_security_group.sonarqube_ecs_sg[0].id]
  }
}

# SonarQube Database Credentials
locals {
  sonardb_connection_string = format(
    "postgresql://%s:%s@%s/%s?sslmode=require",
    aws_db_instance.sonarqube[0].username,
    random_password.sonarqube_rds_password[0].result,
    aws_db_instance.sonarqube[0].endpoint,
    aws_db_instance.sonarqube[0].db_name
  )
}

resource "aws_secretsmanager_secret" "sonardb_credentials" {
  name        = "sonardb-credentials"
  description = "SonarQube Database Credentials"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "sonardb_credentials" {
  secret_id     = aws_secretsmanager_secret.sonardb_credentials[0].id
  secret_string = <<EOF
{
  "username": "${aws_db_instance.sonarqube[0].username}",
  "password": "${random_password.sonarqube_rds_password[0].result}",
  "engine": "${aws_db_instance.sonarqube[0].engine}",
  "host": "${aws_db_instance.sonarqube[0].address}",
  "port": ${aws_db_instance.sonarqube[0].port},
  "dbName": "${aws_db_instance.sonarqube[0].db_name}",
  "dbServerIdentifier": "${aws_db_instance.sonarqube[0].id}",
  "dbConnectionString": "${local.sonardb_connection_string}"
}
EOF
}
