# Entradas para crear log groups de CloudWatch por servicio.
variable "name_prefix" {
  description = "Prefijo para recursos de monitoreo."
  type        = string
}

variable "services" {
  description = "Servicios con log groups."
  type        = set(string)
}

variable "retention_in_days" {
  description = "Retencion de logs en dias."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
