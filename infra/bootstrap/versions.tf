# Define la version minima de Terraform y fija el provider AWS que usa bootstrap.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configura el provider AWS en la region indicada para crear el backend remoto.
provider "aws" {
  region = var.aws_region
}
