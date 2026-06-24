variable "cluster_name" {
  type = string
}
variable "alb_arn_suffix" {
  type = string
}
variable "target_group_arn_suffixes" {
  description = "ARN suffixes de target groups por servicio."
  type        = map(string)
  default     = {}
}

variable "alerta_email" {
  type = string
}

variable "services" {
  description = "Servicios publicados por el ALB."
  type = map(object({
    path_patterns = list(string)
    priority      = number
    health_path   = string
  }))
}

variable "environment" {
  description = "Nombre del ambiente."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
  default     = "devops-retail-store"
}

variable "aws_region" {
  description = "Region de AWS."
  type        = string
  default     = "us-east-1"
}