# Entradas para generar y nombrar secretos de la aplicacion.
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

variable "admin_password" {
  description = "Password inicial del panel admin. Si es null o vacia, se genera automaticamente."
  type        = string
  default     = null
  sensitive   = true
  nullable    = true
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
