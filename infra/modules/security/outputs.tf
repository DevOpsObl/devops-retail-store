output "alb_sg_id" {
  description = "Security group del ALB."
  value       = aws_security_group.alb.id
}

output "ecs_sg_id" {
  description = "Security group de las tareas ECS."
  value       = aws_security_group.ecs.id
}

output "rds_sg_id" {
  description = "Security group de RDS."
  value       = aws_security_group.rds.id
}

output "redis_sg_id" {
  description = "Security group de Redis."
  value       = aws_security_group.redis.id
}

output "lambda_sg_id" {
  description = "Security group de Lambda."
  value       = aws_security_group.lambda.id
}
