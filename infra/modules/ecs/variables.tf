# Entradas del modulo ECS: red privada, roles, logs, target groups y servicios.
variable "name_prefix" {
  description = "Prefijo para recursos ECS."
  type        = string
}

variable "aws_region" {
  description = "Region de AWS."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subredes privadas para tareas Fargate."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group de tareas ECS."
  type        = string
}

variable "lab_role_arn" {
  description = "ARN del rol LabRole usado como task execution role y task role."
  type        = string
}

variable "log_group_names" {
  description = "Log groups de CloudWatch por servicio."
  type        = map(string)
}

variable "target_group_arns" {
  description = "Target groups del ALB por servicio."
  type        = map(string)
  default     = {}
}

variable "services" {
  description = "Definicion de servicios ECS."
  type = map(object({
    image         = string
    cpu           = number
    memory        = number
    desired_count = number
    port          = number
    environment   = map(string)
    secrets       = map(string)
    public        = bool
    validation = object({
      health_path   = string
      expected_body = optional(string)
      smoke_paths   = list(string)
    })
  }))
}

variable "deployment_hook" {
  description = "Configuracion del guardia Lambda ejecutado por ECS en POST_SCALE_UP."
  type = object({
    enabled             = bool
    function_arn        = string
    role_arn            = string
    max_attempts        = number
    retry_delay_seconds = number
    request_timeout_ms  = number
  })
  default = {
    enabled             = false
    function_arn        = ""
    role_arn            = ""
    max_attempts        = 3
    retry_delay_seconds = 30
    request_timeout_ms  = 3000
  }

  validation {
    condition = (
      !var.deployment_hook.enabled ||
      (var.deployment_hook.function_arn != "" && var.deployment_hook.role_arn != "")
    )
    error_message = "function_arn y role_arn son obligatorios cuando deployment_hook.enabled es true."
  }
}

variable "database_init" {
  description = "Configuracion opcional para inicializar bases PostgreSQL antes de crear servicios ECS."
  type = object({
    enabled                    = bool
    host                       = string
    port                       = string
    username                   = string
    initial_database           = string
    password_secret_value_from = string
    databases                  = list(string)
  })
  default = {
    enabled                    = false
    host                       = ""
    port                       = "5432"
    username                   = ""
    initial_database           = "postgres"
    password_secret_value_from = ""
    databases                  = []
  }
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
