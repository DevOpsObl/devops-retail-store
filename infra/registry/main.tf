# Valores derivados que se reutilizan en nombres y tags.
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Scope       = "registry"
    },
    var.tags
  )
}

# Crea los repositorios ECR donde se publican las imagenes Docker.
module "ecr" {
  source = "../modules/ecr"

  name_prefix = local.name_prefix
  services    = var.services
  tags        = local.common_tags
}
