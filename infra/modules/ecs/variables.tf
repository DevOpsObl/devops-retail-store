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
  }))
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
