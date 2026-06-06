output "state_bucket_name" {
  description = "Bucket S3 creado para el estado remoto."
  value       = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "Tabla DynamoDB creada para bloqueo de Terraform."
  value       = aws_dynamodb_table.terraform_locks.name
}
