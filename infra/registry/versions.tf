# Define la version de Terraform y los providers que usa el registry.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Provider AWS para los repositorios ECR del ambiente seleccionado.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
