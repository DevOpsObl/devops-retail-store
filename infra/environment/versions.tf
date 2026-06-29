# Define la version de Terraform y los providers que usa la infraestructura.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.14, < 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Provider AWS para los recursos del ambiente seleccionado.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
