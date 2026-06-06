output "log_group_names" {
  description = "Log groups por servicio."
  value       = { for name, group in aws_cloudwatch_log_group.service : name => group.name }
}
