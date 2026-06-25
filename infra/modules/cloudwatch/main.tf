locals {
  name_prefix = "${var.project_name}-${var.environment}"

  alb_health_metrics = [
    for name, tg_arn_suffix in var.target_group_arn_suffixes : [
      "AWS/ApplicationELB", "HealthyHostCount",
      "LoadBalancer", var.alb_arn_suffix,
      "TargetGroup", tg_arn_suffix,
    ]
  ]
}

resource "aws_cloudwatch_log_group" "servicios" {
  for_each = var.services

  name              = "/ecs/${var.environment}/${each.key}"
  retention_in_days = 30
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-infraestructure"

  dashboard_body = jsonencode({
    widgets = [
      {
        description = "Cluster CPU Utilization"
        type        = "metric"
        properties = {
          title   = "CPU Utilization - ECS"
          region  = var.aws_region
          metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      {
        description = "Cluster Memory Utilization"
        type        = "metric"
        properties = {
          title   = "Memory Utilization - ECS"
          region  = var.aws_region
          metrics = [["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Network Traffic - ALB"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "ProcessedBytes", "LoadBalancer", var.alb_arn_suffix],
          ]
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title   = "ALB Health - Healthy Hosts"
          region  = var.aws_region
          metrics = local.alb_health_metrics
          period  = 60
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      {
        type = "log"
        properties = {
          title         = "Logs - Todos los servicios"
          region        = var.aws_region
          view          = "table"
          logGroupNames = [for k, _ in var.services : "/ecs/${var.environment}/${k}"]
          query         = <<-EOT
      fields @timestamp, @logStream, @message
      | sort @timestamp desc
      | limit 200
    EOT
        }
      }

    ]
  })
}

resource "aws_sns_topic" "alertas" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alertas.arn
  protocol  = "email"
  endpoint  = var.alerta_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_alto" {
  alarm_name          = "${local.name_prefix}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1 # 1 período de 5 min = 5 min consecutivos
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300 # 5 minutos
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_description = "CPU promedio superior al 80% durante 5 minutos"
  alarm_actions     = [aws_sns_topic.alertas.arn]
  ok_actions        = [aws_sns_topic.alertas.arn]
}

resource "aws_cloudwatch_metric_alarm" "memoria_alta" {
  alarm_name          = "${local.name_prefix}-memory-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_description = "Memoria superior al 85% durante 5 minutos"
  alarm_actions     = [aws_sns_topic.alertas.arn]
  ok_actions        = [aws_sns_topic.alertas.arn]
}

# Convierte los logs de `ERROR` en una métrica numérica
resource "aws_cloudwatch_log_metric_filter" "errores_app" {
  for_each = var.services

  name           = "errores-${each.key}"
  log_group_name = aws_cloudwatch_log_group.servicios[each.key].name
  pattern = lookup({
    "catalog"  = "?error ?ERROR"
    "orders"   = "?error ?ERROR"
    "checkout" = "?error ?ERROR"
    "cart"     = "?error ?ERROR"
    "ui"       = "?error ?ERROR"
    "admin"    = "?error ?ERROR"
  }, each.key, "ERROR")

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "${local.name_prefix}/logs"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "errores_app" {
  alarm_name          = "${local.name_prefix}-errores-frecuentes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = "${local.name_prefix}/logs"
  period              = 300
  statistic           = "Sum"
  threshold           = 10

  alarm_description = "Más de 10 errores en 5 minutos"
  alarm_actions     = [aws_sns_topic.alertas.arn]
}