# terraform-aws-sonarqube

A Terraform module for deploying SonarQube on AWS as a containerized service. This module automates the provisioning and management of SonarQube infrastructure using AWS services, making it easy to deploy and manage in your cloud environment.

## Features

This Terraform module deploys a **SonarQube container** in an **AWS Fargate cluster** using the **AWS Graviton (ARM) architecture**. It includes the following components:

- **Amazon ECS (Fargate) Cluster** – Runs the SonarQube container on AWS Graviton-based instances for cost efficiency and performance.
- **Amazon RDS Instance** – Provides a managed PostgreSQL database for SonarQube.
- **Amazon ECR Repository** – Stores the SonarQube Docker image.
- **Amazon Secrets Manager** – Securely stores sensitive information such as database credentials.
- **Application Load Balancer (ALB)** – Manages external access to the SonarQube instance while keeping the platform private.
- **Amazon EFS Volumes** – Ensures persistent storage for SonarQube data.
- **Amazon CloudWatch Log Group** – Captures logs for basic monitoring and troubleshooting.

This setup ensures a **scalable, cost-effective, and secure** SonarQube deployment in AWS.

## Highlights

- **Self-contained deployment** – No external dependencies beyond basic networking.
- **Private Deployment** – The entire infrastructure is **deployed in a private network**, with external access routed exclusively through the **Application Load Balancer (ALB)**.
- **Persistence** – Three file shares are used to persist data, extensions, and logs. This improves **internal Elasticsearch cache performance**, allows **easy integration of third-party plugins**, and **prevents logs** from consuming container space.
- **Automated Logging** – Logs are ingested automatically into **Amazon CloudWatch Logs** for easy troubleshooting and monitoring.
- **Dedicated Container Registry** – Deploys and uses its **own Amazon ECR** repository to bypass Docker Hub’s pull rate limits.
- **Automated Image Handling** – The module automatically pulls the specified SonarQube image tag from **Docker Hub**, pushes it to **Amazon ECR**, and deploys it securely.
- **AWS Graviton (ARM64) architecture** for containers and database, which provides cost savings and improved performance.

## Requirements

- Terraform v1.9
- Docker CLI
- AWS account with necessary IAM permissions
- **Pre-existing networking infrastructure:** This module requires that the VPC, subnets, and networking resources are deployed beforehand.

| Name                         | Description                                           | Type           | Default           | Required |
| ---------------------------- | ----------------------------------------------------- | -------------- | ----------------- | -------- |
| `name`                       | Name to be used on all the resources as an identifier | `string`       | `"sonarqube"`     | no       |
| `tags`                       | A map of tags to add to all resources                 | `map(string)`  | `{}`              | no       |
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
| `sonar_image_tag`            | The Docker Hub tag of the SonarQube image to deploy   | `string`       | N/A               | yes      |

| Name                     | Description                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------------ |
| `sonarqube_cluster_arn`   | The Amazon Resource Name (ARN) of the ECS cluster hosting SonarQube                              |
| `sonarqube_cluster_id`    | The unique identifier (ID) of the ECS cluster hosting SonarQube                                  |
| `sonarqube_cluster_name`  | The name assigned to the ECS cluster hosting SonarQube                                           |
| `alb_arn`                 | The Amazon Resource Name (ARN) of the Application Load Balancer (ALB) managing SonarQube traffic |
| `alb_id`                  | The unique identifier (ID) of the Application Load Balancer (ALB) managing SonarQube traffic     |
| `alb_dns_name`            | The publicly accessible DNS name of the Application Load Balancer (ALB) for SonarQube            |

## Enabling HTTPS Support

This Terraform module does **not** include HTTPS (TLS) support for the AWS Application Load Balancer (ALB) by default for the following reasons:

- **DNS & Certificate Complexity**: Automating HTTPS across all use cases is challenging. Different organizations use various **DNS providers, certificate authorities (CAs), and domain types**, some of which are not natively supported in certain cloud environments.
- **Flexibility for Users**: HTTPS implementation varies based on **security policies, internal PKI infrastructure, and certificate lifecycle management**. Providing a one-size-fits-all approach could introduce unnecessary constraints.
- **User Control**: Delegating TLS configuration allows users to integrate with **existing certificate automation workflows** and manage domain-specific requirements independently.

### How to Enable HTTPS Manually

To introduce HTTPS support for your SonarQube deployment, follow these steps:

1. **Assign a Custom Domain**
   - Ensure that your **AWS Application Load Balancer (ALB)** is associated with a **custom domain name** (e.g., `sonarqube.example.com`).
   - Update your **DNS provider** to point the domain to the **ALB DNS name**.

2. **Generate or Import a TLS Certificate**
   - If using **AWS Certificate Manager (ACM)**, request or import an SSL certificate for your domain.
   - Alternatively, you can generate a **self-signed certificate** for internal use, though it’s recommended to use a certificate from a trusted CA for production environments.

3. **Configure HTTPS Listener on Application Load Balancer**
   - Update the **Application Load Balancer configuration** to:
     - Create a **new HTTPS listener** on port **443**.
     - Attach the generated/imported **TLS certificate** to the listener.
     - Ensure that the backend HTTP traffic is properly forwarded to the SonarQube container.

By following these steps, users can enable HTTPS while maintaining flexibility over their **certificate management, domain setup, and security policies**.

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

[![banner](https://raw.githubusercontent.com/nearform/.github/refs/heads/master/assets/os-banner-green.svg)](https://www.nearform.com/contact/?utm_source=open-source&utm_medium=banner&utm_campaign=os-project-pages)
