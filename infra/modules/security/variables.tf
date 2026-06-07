# Entradas del modulo de seguridad: VPC destino, prefijo de nombres y tags.
variable "name_prefix" {
  description = "Prefijo para nombrar security groups."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC."
  type        = string
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
