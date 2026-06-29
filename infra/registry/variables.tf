# Region AWS usada por los repositorios ECR.
variable "aws_region" {
  description = "Region de AWS."
  type        = string
  default     = "us-east-1"
}

# Nombre logico del proyecto; se usa para nombres y tags.
variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
  default     = "devops-retail-store"
}

# Ambiente asociado a los repositorios ECR.
variable "environment" {
  description = "Nombre del ambiente."
  type        = string
  default     = "dev"
}

# Servicios que tendran repositorio ECR.
variable "services" {
  description = "Servicios que tendran repositorio ECR."
  type        = set(string)
  default     = ["ui", "admin", "catalog", "cart", "checkout", "orders"]
}

# Tags adicionales aplicados a los recursos.
variable "tags" {
  description = "Tags adicionales."
  type        = map(string)
  default     = {}
}
