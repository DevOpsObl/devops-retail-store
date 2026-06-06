output "alb_dns_name" {
  description = "DNS publico del Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "ID de la VPC."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de subredes publicas."
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de subredes privadas."
  value       = module.networking.private_subnet_ids
}

output "ecr_repository_urls" {
  description = "URLs de ECR para publicar las imagenes Docker."
  value       = module.ecr.repository_urls
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS."
  value       = module.ecs.cluster_name
}

output "ecs_service_names" {
  description = "Servicios ECS creados."
  value       = module.ecs.service_names
}

output "rds_endpoint" {
  description = "Endpoint de PostgreSQL RDS."
  value       = module.database.endpoint
}

output "redis_endpoint" {
  description = "Endpoint de Redis ElastiCache."
  value       = "${module.redis.endpoint}:${module.redis.port}"
}

output "secret_arn" {
  description = "ARN del secreto con credenciales."
  value       = module.secrets.secret_arn
}

output "lambda_function_name" {
  description = "Lambda de automatizacion."
  value       = module.lambda.function_name
}
