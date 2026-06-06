variable "name_prefix" {
  description = "Prefijo para nombrar recursos."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR principal de la VPC."
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidad a utilizar."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs de subredes publicas."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs de subredes privadas."
  type        = list(string)
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
