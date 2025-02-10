output "sonarqube_cluster_arn" {
  description = "ARN that identifies the cluster"
  value       = aws_ecs_cluster.sonarqube.arn
}

output "sonarqube_cluster_id" {
  description = "ID that identifies the cluster"
  value       = aws_ecs_cluster.sonarqube.id
}

output "sonarqube_cluster_name" {
  description = "Name that identifies the cluster"
  value       = aws_ecs_cluster.sonarqube.name
}
