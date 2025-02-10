output "sonarqube_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the ECS cluster hosting SonarQube"
  value       = aws_ecs_cluster.sonarqube.arn
}

output "sonarqube_cluster_id" {
  description = "The unique identifier (ID) of the ECS cluster hosting SonarQube"
  value       = aws_ecs_cluster.sonarqube.id
}

output "sonarqube_cluster_name" {
  description = "The name assigned to the ECS cluster hosting SonarQube"
  value       = aws_ecs_cluster.sonarqube.name
}

output "alb_arn" {
  description = "The Amazon Resource Name (ARN) of the Application Load Balancer (ALB) managing SonarQube traffic"
  value       = aws_lb.sonarqube.arn
}

output "alb_id" {
  description = "The unique identifier (ID) of the Application Load Balancer (ALB) managing SonarQube traffic"
  value       = aws_lb.sonarqube.id
}

output "alb_dns_name" {
  description = "The publicly accessible DNS name of the Application Load Balancer (ALB) for SonarQube"
  value       = aws_lb.sonarqube.dns_name
}
