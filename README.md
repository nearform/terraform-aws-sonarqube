# terraform-aws-sonarqube

A Terraform module for deploying SonarQube on AWS as a containerized service. This module automates the provisioning and management of SonarQube infrastructure using AWS services, making it easy to deploy and manage in your cloud environment.

## Features

This Terraform module deploys a **SonarQube container** in an **AWS Fargate cluster** using the **AWS Graviton (ARM) architecture**. It includes the following components:

- **Amazon ECS (Fargate) Cluster** – Runs the SonarQube container on AWS Graviton-based instances for cost efficiency and performance.
- **Amazon RDS Instance** – Provides a managed PostgreSQL database for SonarQube.
- **Amazon ECR Repository** – Stores the SonarQube Docker image. The image is automatically pulled from **Docker Hub**, tagged, and pushed to ECR to avoid **Docker Hub pull limits**.
- **Application Load Balancer (ALB)** – Manages external access to the SonarQube instance while keeping the platform private.
- **Amazon EFS Volumes** – Ensures persistent storage for SonarQube data.
- **Amazon CloudWatch Log Group** – Captures logs for basic monitoring and troubleshooting.
- **Private Deployment** – The entire infrastructure is **deployed in a private network**, with external access strictly routed through the **Application Load Balancer (ALB)**.

This setup ensures a **scalable, cost-effective, and secure** SonarQube deployment in AWS.

## Requirements

- Terraform v1.9
- Docker CLI
- AWS account with necessary IAM permissions
- **Pre-existing networking infrastructure:** This module requires that the VPC, subnets, and networking resources are deployed beforehand.

## Inputs

| Name                         | Description                                           | Type           | Default           | Required |
| ---------------------------- | ----------------------------------------------------- | -------------- | ----------------- | -------- |
| `name`                       | Name to be used on all the resources as an identifier | `string`       | `"sonarqube"`     | no       |
| `tags`                       | A map of tags to add to all resources                 | `map(string)`  | `{}`              | no       |
| `sonar_image_tag`            | The Docker Hub tag of the SonarQube image to deploy   | `string`       | N/A               | yes      |
| `vpc_id`                     | ID of the VPC                                         | `string`       | N/A               | yes      |
| `database_subnets`           | List of IDs of database subnets                       | `list(string)` | N/A               | yes      |
| `database_subnet_group_name` | Name of database subnet group                         | `string`       | N/A               | yes      |
| `private_subnets`            | List of IDs of private subnets                        | `list(string)` | N/A               | yes      |
| `public_subnets`             | List of IDs of public subnets                         | `list(string)` | N/A               | yes      |
| `sonar_db_server`            | The name of the SonarQube database server             | `string`       | `"sonardbserver"` | no       |
| `sonar_db_instance_class`    | The SonarQube database server instance class          | `string`       | `"db.t4g.micro"`  | no       |
| `sonar_db_storage_type`      | The SonarQube database server storage type            | `string`       | `"gp2"`           | no       |
| `sonar_db_name`              | The name of the SonarQube database                    | `string`       | `"sonar"`         | no       |
| `sonar_db_user`              | The username for the SonarQube database               | `string`       | `"sonar"`         | no       |
| `sonar_port`                 | The port on which SonarQube will run                  | `number`       | `9000`            | no       |
| `sonar_container_name`       | The name of the SonarQube container                   | `string`       | `"sonarqube"`     | no       |

## Outputs

| Name                     | Description                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------------ |
| `sonarqube_cluster_arn`  | The Amazon Resource Name (ARN) of the ECS cluster hosting SonarQube                              |
| `sonarqube_cluster_id`   | The unique identifier (ID) of the ECS cluster hosting SonarQube                                  |
| `sonarqube_cluster_name` | The name assigned to the ECS cluster hosting SonarQube                                           |
| `alb_id`                 | The unique identifier (ID) of the Application Load Balancer (ALB) managing SonarQube traffic     |
| `alb_arn`                | The Amazon Resource Name (ARN) of the Application Load Balancer (ALB) managing SonarQube traffic |
| `alb_dns_name`           | The publicly accessible DNS name of the Application Load Balancer (ALB) for SonarQube            |

## Examples

### **Basic Usage**

The following example deploys SonarQube in AWS using the Terraform module.

```hcl
module "sonarqube" {
  source = "github.com/nearform/terraform-aws-sonarqube"

  # General Configuration
  name  = "sonarqube"
  tags  = {
    Environment = "dev"
    Project     = "sonarqube"
  }

  # Networking
  vpc_id                     = "vpc-xxxxxxxx"
  database_subnets           = ["subnet-xxxxxx", "subnet-yyyyyy"]
  private_subnets            = ["subnet-aaaaaa", "subnet-bbbbbb"]
  public_subnets             = ["subnet-cccccc", "subnet-dddddd"]
  database_subnet_group_name = "sonarqube-db-group"

  # SonarQube Configuration
  sonar_db_server          = "sonardbserver"
  sonar_db_instance_class  = "db.t4g.micro"
  sonar_db_storage_type    = "gp2"
  sonar_db_name            = "sonar"
  sonar_db_user            = "sonar"
  sonar_port               = 9000
  sonar_container_name     = "sonarqube"
  sonar_image_tag          = "community"
}
```

### Customizing SonarQube Version

You can specify a different version of the SonarQube Docker image by setting the sonar_image_tag variable:

```hcl
sonar_image_tag = "9.9.1-community"
```

### Using a Different Database Instance

If you need a larger database instance for better performance:

```hcl
sonar_db_instance_class = "db.t3.medium"
```

## Contributing

We welcome contributions to improve this Terraform module! Here’s how you can contribute:

1. **Fork the repository** - Create a personal fork of this repository to make your changes.
2. **Create a new branch** - For each contribution, create a new branch from `main`.
3. **Make your changes** - Implement your changes, and ensure that the code adheres to the existing style.
4. **Write tests** - If applicable, write tests to cover your changes.
5. **Commit and push** - Commit your changes with descriptive messages and push them to your fork.
6. **Create a pull request** - Open a pull request from your fork’s branch to the main repository’s `main` branch.
7. **Be respectful** - Be mindful and respectful in discussions.

For larger changes or new features, please open an issue first to discuss the approach before starting work on it.

Thanks for helping improve this project!
