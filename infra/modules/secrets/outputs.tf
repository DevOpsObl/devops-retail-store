# Salidas del secreto. La password se marca sensitive para no imprimirla accidentalmente.
output "secret_arn" {
  description = "ARN del secreto con credenciales de aplicacion."
  value       = aws_secretsmanager_secret.app.arn
}

output "db_password" {
  description = "Password generado para PostgreSQL."
  value       = random_password.db.result
  sensitive   = true
}

output "db_username" {
  description = "Usuario PostgreSQL."
  value       = var.db_username
}
