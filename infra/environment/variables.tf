variable "aws_region" {
  description = "Region de AWS."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
  default     = "devops-retail-store"
}

variable "environment" {
  description = "Nombre del ambiente."
  type        = string
  default     = "dev"
}

variable "lab_role_name" {
  description = "Nombre del rol IAM provisto por AWS Academy/Lab."
  type        = string
  default     = "LabRole"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs de subredes publicas."
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs de subredes privadas."
  type        = list(string)
  default     = ["10.40.11.0/24", "10.40.12.0/24"]
}

variable "image_tag" {
  description = "Tag de imagen Docker a desplegar desde ECR."
  type        = string
  default     = "latest"
}

variable "db_username" {
  description = "Usuario maestro de PostgreSQL."
  type        = string
  default     = "retail_user"
}

variable "db_instance_class" {
  description = "Clase de instancia RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "redis_node_type" {
  description = "Tipo de nodo ElastiCache Redis."
  type        = string
  default     = "cache.t3.micro"
}

variable "service_desired_count" {
  description = "Cantidad deseada de replicas por servicio."
  type        = map(number)
  default = {
    ui       = 1
    admin    = 1
    catalog  = 1
    carts    = 1
    checkout = 1
    orders   = 1
  }
}

variable "service_cpu" {
  description = "CPU Fargate por servicio."
  type        = map(number)
  default = {
    ui       = 256
    admin    = 256
    catalog  = 256
    carts    = 256
    checkout = 256
    orders   = 256
  }
}

variable "service_memory" {
  description = "Memoria Fargate por servicio."
  type        = map(number)
  default = {
    ui       = 512
    admin    = 512
    catalog  = 512
    carts    = 512
    checkout = 512
    orders   = 512
  }
}

variable "tags" {
  description = "Tags adicionales."
  type        = map(string)
  default     = {}
}
