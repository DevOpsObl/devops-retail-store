# Region AWS usada por todos los recursos del ambiente.
variable "aws_region" {
  description = "Region de AWS."
  type        = string
  default     = "us-east-1"
}

# Nombre logico del proyecto; se usa para nombres y tags.
variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
  default     = "devops-retail-store"
}

# Ambiente a desplegar. Impacta nombres, tags y archivo de estado.
variable "environment" {
  description = "Nombre del ambiente."
  type        = string
  default     = "dev"
}

# Rol IAM disponible en el laboratorio AWS para ECS, Lambda y permisos asociados.
variable "lab_role_name" {
  description = "Nombre del rol IAM provisto por AWS Academy/Lab."
  type        = string
  default     = "LabRole"
}

# CIDR principal de la VPC del ambiente.
variable "vpc_cidr" {
  description = "CIDR de la VPC."
  type        = string
  default     = "10.40.0.0/16"
}

# Zonas de disponibilidad donde se distribuyen subredes y servicios.
variable "availability_zones" {
  description = "Zonas de disponibilidad."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# CIDRs de subredes publicas para ALB, Internet Gateway y NAT Gateway.
variable "public_subnet_cidrs" {
  description = "CIDRs de subredes publicas."
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24"]
}

# CIDRs de subredes privadas para ECS Fargate, RDS y Redis.
variable "private_subnet_cidrs" {
  description = "CIDRs de subredes privadas."
  type        = list(string)
  default     = ["10.40.11.0/24", "10.40.12.0/24"]
}

# Tag de las imagenes Docker que ECS intentara ejecutar desde ECR.
variable "image_tag" {
  description = "Tag de imagen Docker a desplegar desde ECR."
  type        = string
  default     = "latest"
}

# Usuario maestro de PostgreSQL. La password se genera en Secrets Manager.
variable "db_username" {
  description = "Usuario maestro de PostgreSQL."
  type        = string
  default     = "retail_user"
}

# Tamano de instancia RDS usado por PostgreSQL.
variable "db_instance_class" {
  description = "Clase de instancia RDS."
  type        = string
  default     = "db.t3.micro"
}

# Tamano de nodo ElastiCache usado por Redis.
variable "redis_node_type" {
  description = "Tipo de nodo ElastiCache Redis."
  type        = string
  default     = "cache.t3.micro"
}

# Cantidad deseada de tareas ECS por microservicio.
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

# CPU Fargate asignada a cada microservicio.
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

# Memoria Fargate asignada a cada microservicio.
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

# Tags adicionales mezclados con los tags comunes del ambiente.
variable "tags" {
  description = "Tags adicionales."
  type        = map(string)
  default     = {}
}
