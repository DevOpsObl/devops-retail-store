# Datos del ALB que consume el ambiente y el modulo ECS.
output "alb_dns_name" {
  description = "DNS publico del Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer."
  value       = aws_lb.this.arn
}

output "target_group_arns" {
  description = "ARNs de target groups por servicio."
  value       = { for name, tg in aws_lb_target_group.service : name => tg.arn }
}

output "target_group_arn_suffixes" {
  description = "ARNs suffixes de target groups por servicio."
  value       = { for name, tg in aws_lb_target_group.service : name => tg.arn_suffix }
}

output "alb_arn_suffix" {
  description = "ARN del Application Load Balancer."
  value       = aws_lb.this.arn_suffix
}