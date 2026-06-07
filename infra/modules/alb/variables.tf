# Entradas del ALB: red, security group y reglas de servicios.
variable "name_prefix" {
  description = "Prefijo para nombrar recursos."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subredes publicas para el ALB."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group del ALB."
  type        = string
}

variable "services" {
  description = "Servicios publicados por el ALB."
  type = map(object({
    path_patterns = list(string)
    priority      = number
    health_path   = string
  }))
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
