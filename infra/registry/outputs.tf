# Repositorios donde se deben publicar las imagenes Docker.
output "ecr_repository_urls" {
  description = "URLs de ECR para publicar las imagenes Docker."
  value       = module.ecr.repository_urls
}

# ARNs de los repositorios ECR del ambiente.
output "ecr_repository_arns" {
  description = "ARNs de los repositorios ECR."
  value       = module.ecr.repository_arns
}
