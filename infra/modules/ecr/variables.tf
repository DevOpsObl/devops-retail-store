# Entradas para crear repositorios ECR por microservicio.
variable "name_prefix" {
  description = "Prefijo para los repositorios ECR."
  type        = string
}

variable "services" {
  description = "Servicios que tendran repositorio ECR."
  type        = set(string)
}

variable "image_tag_mutability" {
  description = "Mutabilidad de tags de imagen."
  type        = string
  default     = "MUTABLE"
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
