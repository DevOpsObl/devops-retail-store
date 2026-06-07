# Entradas para desplegar la Lambda de automatizacion con LabRole.
variable "name_prefix" {
  description = "Prefijo para Lambda."
  type        = string
}

variable "lab_role_arn" {
  description = "ARN del rol LabRole."
  type        = string
}

variable "subnet_ids" {
  description = "Subredes privadas para Lambda."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups de Lambda."
  type        = list(string)
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
