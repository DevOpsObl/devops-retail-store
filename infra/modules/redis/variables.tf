# Entradas para el cluster Redis administrado en ElastiCache.
variable "name_prefix" {
  description = "Prefijo para Redis."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subredes privadas para Redis."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group de Redis."
  type        = string
}

variable "node_type" {
  description = "Tipo de nodo Redis."
  type        = string
  default     = "cache.t3.micro"
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
