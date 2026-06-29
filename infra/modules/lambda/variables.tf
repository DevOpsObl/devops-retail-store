variable "name_prefix" {
  description = "Prefijo para recursos del guardia de despliegue."
  type        = string
}

variable "lab_role_arn" {
  description = "ARN del LabRole usado como execution role de Lambda. Debe permitir logs, ECS Describe/List y SNS Publish."
  type        = string
}

variable "ecs_hook_role_arn" {
  description = "Rol existente que ECS puede asumir para invocar la Lambda. Si es null, el modulo crea uno de minimo privilegio."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.ecs_hook_role_arn == null || trimspace(var.ecs_hook_role_arn) != ""
    error_message = "ecs_hook_role_arn debe ser null o un ARN no vacio."
  }
}

variable "subnet_ids" {
  description = "Subredes privadas desde las que Lambda consulta las tasks nuevas."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups de la Lambda."
  type        = list(string)
}

variable "alert_email" {
  description = "Email opcional que se suscribe al tema SNS de fallas de deployment."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
