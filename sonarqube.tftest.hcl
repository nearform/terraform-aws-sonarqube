# Credential-free compliance checks for the SonarQube module.
# Replaces terraform-compliance BDD features (features/*.feature) using native
# Terraform mocking — no AWS account or emulator required.

mock_provider "aws" {
  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:eu-west-1:123456789012:key/sonarqube-test"
    }
  }
}

override_resource {
  target = aws_kms_key.sonarqube
  values = {
    arn = "arn:aws:kms:eu-west-1:123456789012:key/sonarqube-test"
  }
  override_during = plan
}

variables {
  sonar_image_tag            = "10.7.0-community"
  vpc_id                     = "vpc-test123"
  database_subnets           = ["subnet-db-1", "subnet-db-2"]
  database_subnet_group_name = "test-db-subnet-group"
  private_subnets            = ["subnet-private-1", "subnet-private-2"]
  public_subnets             = ["subnet-public-1", "subnet-public-2"]
}

run "plan_and_verify_module" {
  command = plan

  # ECS — features/ecs.feature
  assert {
    condition     = contains(aws_ecs_task_definition.sonarqube.requires_compatibilities, "FARGATE")
    error_message = "ECS task definition must use Fargate compatibility."
  }

  assert {
    condition     = aws_ecs_task_definition.sonarqube.network_mode == "awsvpc"
    error_message = "ECS task definition network mode must be awsvpc."
  }

  assert {
    condition     = aws_ecs_task_definition.sonarqube.runtime_platform[0].operating_system_family == "LINUX"
    error_message = "ECS task definition runtime platform must use Linux."
  }

  assert {
    condition     = aws_ecs_task_definition.sonarqube.runtime_platform[0].cpu_architecture == "ARM64"
    error_message = "ECS task definition runtime platform must use ARM64."
  }

  assert {
    condition = alltrue([
      for required_volume in ["sonar-data", "sonar-extensions", "sonar-logs"] :
      contains([for volume in aws_ecs_task_definition.sonarqube.volume : volume.name], required_volume)
    ])
    error_message = "ECS task definition must define sonar-data, sonar-extensions, and sonar-logs volumes."
  }

  # RDS — features/rds.feature
  assert {
    condition     = aws_db_instance.sonarqube.engine == "postgres"
    error_message = "RDS instance engine must be postgres."
  }

  assert {
    condition     = aws_db_instance.sonarqube.engine_version == "16"
    error_message = "RDS instance engine version must be 16."
  }

  assert {
    condition     = aws_db_instance.sonarqube.publicly_accessible == false
    error_message = "RDS instance must not be publicly accessible."
  }

  assert {
    condition     = aws_db_instance.sonarqube.deletion_protection == true
    error_message = "RDS instance must have deletion protection enabled."
  }

  assert {
    condition     = aws_db_instance.sonarqube.storage_encrypted == true
    error_message = "RDS instance storage must be encrypted."
  }

  assert {
    condition     = aws_db_instance.sonarqube.kms_key_id == aws_kms_key.sonarqube.arn
    error_message = "RDS instance must use the module KMS key for storage encryption."
  }

  # ALB — features/alb.feature
  assert {
    condition     = aws_lb.sonarqube.load_balancer_type == "application"
    error_message = "Load balancer must be an Application Load Balancer."
  }

  assert {
    condition     = aws_lb_target_group.sonarqube.protocol == "HTTP"
    error_message = "Target group protocol must be HTTP."
  }

  assert {
    condition     = aws_lb_target_group.sonarqube.target_type == "ip"
    error_message = "Target group target type must be ip."
  }

  assert {
    condition     = aws_lb_listener.sonarqube_http_listener.protocol == "HTTP"
    error_message = "ALB listener protocol must be HTTP."
  }

  assert {
    condition     = aws_lb_listener.sonarqube_http_listener.port == 80
    error_message = "ALB listener port must be 80."
  }

  assert {
    condition     = aws_lb_listener.sonarqube_http_listener.default_action[0].type == "forward"
    error_message = "ALB listener default action must forward to the target group."
  }

  # ECR — features/ecr.feature
  assert {
    condition     = aws_ecr_repository.sonarqube.image_tag_mutability == "IMMUTABLE"
    error_message = "ECR repository image tags must be immutable."
  }

  assert {
    condition     = aws_ecr_repository.sonarqube.image_scanning_configuration[0].scan_on_push == true
    error_message = "ECR repository must scan images on push."
  }

  assert {
    condition     = aws_ecr_repository.sonarqube.encryption_configuration[0].encryption_type == "AES256"
    error_message = "ECR repository encryption type must be AES256."
  }

  # CloudWatch — features/cloudwatch.feature
  assert {
    condition     = can(regex("^/aws/ecs/", aws_cloudwatch_log_group.sonarqube_cloudwatch_lg.name))
    error_message = "CloudWatch log group name must be under /aws/ecs/."
  }

  assert {
    condition     = aws_cloudwatch_log_group.sonarqube_cloudwatch_lg.retention_in_days == 7
    error_message = "CloudWatch log group retention must be 7 days."
  }
}
