# Salidas del secreto. La password se marca sensitive para no imprimirla accidentalmente.
output "secret_arn" {
  description = "ARN del secreto con credenciales de aplicacion."
  value       = aws_secretsmanager_secret.app.arn
}

output "secret_version_id" {
  description = "Version actual del secreto de aplicacion."
  value       = nonsensitive(aws_secretsmanager_secret_version.app.version_id)
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
