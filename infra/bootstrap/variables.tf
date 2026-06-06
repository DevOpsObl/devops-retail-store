variable "aws_region" {
  description = "Region de AWS donde se crearan los recursos de bootstrap."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto."
  type        = string
  default     = "devops-retail-store"
}

variable "state_bucket_name" {
  description = "Nombre del bucket S3 para el estado remoto de Terraform."
  type        = string
}

variable "lock_table_name" {
  description = "Nombre de la tabla DynamoDB para bloqueo de concurrencia."
  type        = string
  default     = "devops-retail-store-terraform-locks"
}

variable "tags" {
  description = "Tags comunes para los recursos."
  type        = map(string)
  default     = {}
}
