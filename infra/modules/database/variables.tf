# Entradas para la instancia PostgreSQL administrada en RDS.
variable "name_prefix" {
  description = "Prefijo para RDS."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subredes privadas para RDS."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group de RDS."
  type        = string
}

variable "db_name" {
  description = "Base inicial creada por RDS."
  type        = string
  default     = "orders"
}

variable "username" {
  description = "Usuario maestro."
  type        = string
}

variable "password" {
  description = "Password maestro."
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Clase de instancia RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Almacenamiento inicial en GB."
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Omitir snapshot final al destruir."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
