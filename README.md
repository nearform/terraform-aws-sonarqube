# terraform-aws-sonarqube

A Terraform module for deploying SonarQube on AWS as a containerized service. This module automates the provisioning and management of SonarQube infrastructure using AWS services, making it easy to deploy and manage in your cloud environment.

## Features

- Deploys SonarQube as a containerized service on AWS using ECS/Fargate.
- Includes options for configuring SonarQube settings and persistent storage.
- Built with Terraform, enabling easy reuse and modification for different environments.

## Requirements

- Terraform v1.9
- Docker CLI
- AWS account with necessary IAM permissions

## Inputs

| Name                      | Description                                             | Type          | Default         | Required |
|---------------------------|---------------------------------------------------------|---------------|-----------------|----------|
| `name`                    | Name to be used on all the resources as an identifier   | `string`      | `"sonarqube"`   | no       |
| `tags`                    | A map of tags to add to all resources                   | `map(string)` | `{}`            | no       |
| `sonar_image_tag`         | The Docker Hub tag of the SonarQube image to deploy     | `string`      | N/A             | yes      |
| `vpc_id`                  | ID of the VPC                                           | `string`      | N/A             | yes      |
| `database_subnets`        | List of IDs of database subnets                         | `list(string)`| N/A             | yes      |
| `database_subnet_group_name` | Name of database subnet group                        | `string`      | N/A             | yes      |
| `private_subnets`         | List of IDs of private subnets                          | `list(string)`| N/A             | yes      |
| `public_subnets`          | List of IDs of public subnets                           | `list(string)`| N/A             | yes      |
| `sonar_db_server`         | The name of the SonarQube database server              | `string`      | `"sonardbserver"` | no       |
| `sonar_db_instance_class` | The SonarQube database server instance class           | `string`      | `"db.t4g.micro"` | no       |
| `sonar_db_storage_type`   | The SonarQube database server storage type             | `string`      | `"gp2"`         | no       |
| `sonar_db_name`           | The name of the SonarQube database                     | `string`      | `"sonar"`       | no       |
| `sonar_db_user`           | The username for the SonarQube database                | `string`      | `"sonar"`       | no       |
| `sonar_port`              | The port on which SonarQube will run                   | `number`      | `9000`          | no       |
| `sonar_container_name`    | The name of the SonarQube container                    | `string`      | `"sonarqube"`   | no       |

## Outputs

| Name               | Description                                         |
|--------------------|-----------------------------------------------------|
| `sonarqube_cluster_arn`  | The ARN of the ECS cluster where SonarQube is running |
| `sonarqube_cluster_id`  | The ID of the ECS cluster where SonarQube is running |
| `sonarqube_cluster_name`  | The name of the ECS cluster where SonarQube is running |

## Examples

These examples demonstrate both a basic deployment and a custom configuration with additional parameters.

### Basic Usage

```hcl
module "sonarqube" {
  source            = "github.com/neaform/terraform-aws-sonarqube"
  region            = "eu-wast-1"
  instance_type     = "t3.medium"
  sonarqube_version = "8.9.3"
  vpc_id            = "<your-vpc-id>"
  subnet_ids        = ["<your-subnet-id1>", "<your-subnet-id2>"]
}
```

### Custom Configuration

```hcl
module "sonarqube" {
  source            = "github.com/your-org/terraform-aws-sonarqube"
  region            = "us-west-2"
  instance_type     = "t3.large"
  sonarqube_version = "latest"
  vpc_id            = "<your-vpc-id>"
  subnet_ids        = ["<your-subnet-id1>", "<your-subnet-id2>"]
  security_group_ids = ["<your-security-group-id>"]
  tags = {
    Name        = "SonarQube Deployment"
    Environment = "Production"
  }
}
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
