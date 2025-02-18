output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "sonarqube_cluster_name" {
  description = "The name assigned to the ECS cluster hosting SonarQube"
  value       = module.sonarqube.sonarqube_cluster_name
}

output "alb_dns_name" {
  description = "The publicly accessible DNS name of the Application Load Balancer (ALB) for SonarQube"
  value       = module.sonarqube.alb_dns_name
}
