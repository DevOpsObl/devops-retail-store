output "state_bucket_name" {
  description = "Bucket S3 creado para el estado remoto."
  value       = aws_s3_bucket.terraform_state.id
}
