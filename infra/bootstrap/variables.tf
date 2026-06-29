# Region donde se crean los recursos de bootstrap del estado remoto.
variable "aws_region" {
  description = "Region de AWS donde se crearan los recursos de bootstrap."
  type        = string
  default     = "us-east-1"
}

# Nombre base usado para tags y convenciones del proyecto.
variable "project_name" {
  description = "Nombre base del proyecto."
  type        = string
  default     = "devops-retail-store"
}

# Bucket S3 que guardara los archivos terraform.tfstate de los ambientes.
variable "state_bucket_name" {
  description = "Nombre del bucket S3 para el estado remoto de Terraform."
  type        = string
}

# Tags adicionales para identificar costos, curso, ambiente u ownership.
variable "tags" {
  description = "Tags comunes para los recursos."
  type        = map(string)
  default     = {}
}
