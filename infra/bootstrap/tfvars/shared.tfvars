aws_region   = "us-east-1"
project_name = "devops-retail-store"
# El nombre del bucket S3 debe ser unico globalmente en AWS.
state_bucket_name = "devops-retail-store-terraform-state-lab"
lock_table_name   = "devops-retail-store-terraform-locks"

tags = {
  Course = "TallerDevOps"
}
