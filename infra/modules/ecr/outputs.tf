output "repository_urls" {
  description = "URLs de repositorios ECR por servicio."
  value       = { for name, repo in aws_ecr_repository.service : name => repo.repository_url }
}

output "repository_arns" {
  description = "ARNs de repositorios ECR por servicio."
  value       = { for name, repo in aws_ecr_repository.service : name => repo.arn }
}
