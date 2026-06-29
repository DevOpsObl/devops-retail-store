# Application Load Balancer publico que recibe trafico HTTP de usuarios.
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = var.tags
}

# Target group por microservicio. ECS registra tareas Fargate por IP.
resource "aws_lb_target_group" "service" {
  for_each = var.services

  name        = substr("${var.name_prefix}-${each.key}", 0, 32)
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = each.value.health_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = var.tags
}

# Listener HTTP principal. Por defecto envia trafico a la UI.
resource "aws_lb_listener" "http" {
  # nosemgrep: terraform.aws.security.insecure-load-balancer-tls-version
  # Ambiente de laboratorio sin dominio/certificado ACM. En produccion debe usarse HTTPS con TLS 1.2+.

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["ui"].arn
  }
}

# Reglas por path para enrutar /catalog, /carts, /checkout, /orders y admin.
resource "aws_lb_listener_rule" "service" {
  for_each = {
    for name, config in var.services : name => config
    if name != "ui"
  }

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }
}
