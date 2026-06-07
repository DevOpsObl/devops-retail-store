# Cluster ECS que agrupa los servicios Fargate del ambiente.
resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# Task definition por microservicio. Define imagen, recursos, variables, secretos y logs.
resource "aws_ecs_task_definition" "service" {
  for_each = var.services

  family                   = "${var.name_prefix}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = true
      portMappings = [
        {
          containerPort = each.value.port
          hostPort      = each.value.port
          protocol      = "tcp"
        }
      ]
      # Variables no sensibles que puede ver la task definition.
      environment = [
        for name, value in each.value.environment : {
          name  = name
          value = value
        }
      ]
      # Variables sensibles leidas desde Secrets Manager en tiempo de ejecucion.
      secrets = [
        for name, value_from in each.value.secrets : {
          name      = name
          valueFrom = value_from
        }
      ]
      # Envia stdout/stderr del contenedor al log group correspondiente.
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_names[each.key]
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = each.key
        }
      }
    }
  ])

  tags = var.tags
}

# Servicio ECS Fargate por microservicio. Mantiene la cantidad deseada de tareas.
resource "aws_ecs_service" "service" {
  for_each = var.services

  name            = "${var.name_prefix}-${each.key}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  # Registra la task en el target group del ALB cuando el servicio es publico.
  dynamic "load_balancer" {
    for_each = each.value.public && contains(keys(var.target_group_arns), each.key) ? [1] : []

    content {
      target_group_arn = var.target_group_arns[each.key]
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  tags = var.tags
}
