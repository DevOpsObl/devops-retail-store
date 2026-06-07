# DNS publico del ALB para acceder a la aplicacion y probar endpoints.
output "alb_dns_name" {
  description = "DNS publico del Application Load Balancer."
  value       = module.alb.alb_dns_name
}

# ID de la VPC creada para el ambiente.
output "vpc_id" {
  description = "ID de la VPC."
  value       = module.networking.vpc_id
}

# Subredes publicas donde vive el ALB y el NAT Gateway.
output "public_subnet_ids" {
  description = "IDs de subredes publicas."
  value       = module.networking.public_subnet_ids
}

# Subredes privadas donde corren ECS, RDS y Redis.
output "private_subnet_ids" {
  description = "IDs de subredes privadas."
  value       = module.networking.private_subnet_ids
}

# Repositorios donde se deben publicar las imagenes Docker.
output "ecr_repository_urls" {
  description = "URLs de ECR para publicar las imagenes Docker."
  value       = module.ecr.repository_urls
}

# Nombre del cluster ECS Fargate.
output "ecs_cluster_name" {
  description = "Nombre del cluster ECS."
  value       = module.ecs.cluster_name
}

# Servicios ECS creados para cada microservicio.
output "ecs_service_names" {
  description = "Servicios ECS creados."
  value       = module.ecs.service_names
}

# Endpoint de PostgreSQL usado por catalog, carts, orders y admin.
output "rds_endpoint" {
  description = "Endpoint de PostgreSQL RDS."
  value       = module.database.endpoint
}

# Endpoint de Redis usado por checkout.
output "redis_endpoint" {
  description = "Endpoint de Redis ElastiCache."
  value       = "${module.redis.endpoint}:${module.redis.port}"
}

# ARN del secreto con credenciales generadas para RDS y admin.
output "secret_arn" {
  description = "ARN del secreto con credenciales."
  value       = module.secrets.secret_arn
}

# Nombre de la Lambda de automatizacion operativa.
output "lambda_function_name" {
  description = "Lambda de automatizacion."
  value       = module.lambda.function_name
}
