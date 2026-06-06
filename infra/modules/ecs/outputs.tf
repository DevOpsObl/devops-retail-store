output "cluster_name" {
  description = "Nombre del cluster ECS."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN del cluster ECS."
  value       = aws_ecs_cluster.this.arn
}

output "service_names" {
  description = "Nombres de servicios ECS."
  value       = { for name, service in aws_ecs_service.service : name => service.name }
}
