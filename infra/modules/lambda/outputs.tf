output "function_name" {
  description = "Nombre de la Lambda guardia de despliegue."
  value       = aws_lambda_function.deployment_validator.function_name
}

output "function_arn" {
  description = "ARN de la Lambda guardia de despliegue."
  value       = aws_lambda_function.deployment_validator.arn
}

output "ecs_hook_role_arn" {
  description = "Rol que ECS usa para invocar el hook Lambda."
  value       = local.ecs_hook_role_arn
  depends_on  = [aws_iam_role_policy.ecs_hook]
}

output "alert_topic_arn" {
  description = "Tema SNS que recibe las fallas definitivas de validacion."
  value       = aws_sns_topic.deployment_alerts.arn
}
