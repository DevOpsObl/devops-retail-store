# Endpoints de RDS usados por los servicios de aplicacion.
output "endpoint" {
  description = "Endpoint host:port de RDS."
  value       = aws_db_instance.postgres.endpoint
}

output "address" {
  description = "Hostname de RDS."
  value       = aws_db_instance.postgres.address
}

output "port" {
  description = "Puerto de RDS."
  value       = aws_db_instance.postgres.port
}

output "db_instance_identifier" {
  description = "Identificador de RDS."
  value       = aws_db_instance.postgres.identifier
}
