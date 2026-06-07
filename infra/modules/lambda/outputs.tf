# Identificadores de la Lambda para operacion e integracion.
output "function_name" {
  description = "Nombre de la Lambda de automatizacion."
  value       = aws_lambda_function.automation.function_name
}

output "function_arn" {
  description = "ARN de la Lambda de automatizacion."
  value       = aws_lambda_function.automation.arn
}
