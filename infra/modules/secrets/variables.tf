variable "name_prefix" {
  description = "Prefijo para secretos."
  type        = string
}

variable "db_username" {
  description = "Usuario maestro de PostgreSQL."
  type        = string
}

variable "admin_username" {
  description = "Usuario inicial del panel admin."
  type        = string
  default     = "admin"
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
