# terraform-aws-sonarqube

A Terraform module for deploying SonarQube on AWS as a containerized service. This module automates the provisioning and management of SonarQube infrastructure using AWS services, making it easy to deploy and manage in your cloud environment.

## Features

- Deploys SonarQube as a containerized service on AWS using ECS (Elastic Container Service).
- Includes options for configuring SonarQube settings and persistent storage.
- Built with Terraform, enabling easy reuse and modification for different environments.

## Requirements

- Terraform vX.X.X or higher
- AWS account with necessary IAM permissions

## Inputs

| Name               | Description                                        | Type          | Default      | Required |
|--------------------|----------------------------------------------------|---------------|--------------|----------|
| `instance_type`    | EC2 instance type for SonarQube ECS task           | `string`      | `t2.medium`  | no       |
| `region`            | AWS region where the resources will be deployed    | `string`      | `us-east-1`  | no       |
| `sonarqube_version` | Version of SonarQube to deploy                     | `string`      | `latest`     | no       |
| `vpc_id`            | VPC ID for the SonarQube deployment                | `string`      | N/A          | yes      |
| `subnet_ids`        | List of subnet IDs for SonarQube ECS tasks         | `list(string)`| N/A          | yes      |
| `security_group_ids`| List of security group IDs to attach to SonarQube  | `list(string)`| `[]`         | no       |
| `tags`              | Tags to assign to the created resources            | `map(string)` | `{}`         | no       |

## Outputs

| Name               | Description                                         |
|--------------------|-----------------------------------------------------|
| `sonarqube_url`     | The public URL to access SonarQube once deployed.   |
| `sonarqube_ip`      | The public IP address of the SonarQube instance.    |
| `ecs_cluster_name`  | The name of the ECS cluster where SonarQube is running. |
| `load_balancer_dns` | The DNS name of the load balancer used for SonarQube. |

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
