# Cluster ECS que agrupa los servicios Fargate del ambiente.
resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

locals {
  database_init_sql = <<-SQL
    SELECT 'CREATE DATABASE catalogdb' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'catalogdb')\gexec
    SELECT 'CREATE DATABASE cartdb' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'cartdb')\gexec

    GRANT ALL PRIVILEGES ON DATABASE catalogdb TO :"app_user";
    GRANT ALL PRIVILEGES ON DATABASE cartdb TO :"app_user";
    GRANT ALL PRIVILEGES ON DATABASE orders TO :"app_user";

    \connect orders
    GRANT ALL ON SCHEMA public TO :"app_user";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO :"app_user";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO :"app_user";

    \connect catalogdb
    GRANT ALL ON SCHEMA public TO :"app_user";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO :"app_user";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO :"app_user";

    \connect cartdb
    GRANT ALL ON SCHEMA public TO :"app_user";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO :"app_user";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO :"app_user";

    CREATE TABLE IF NOT EXISTS cart_items (
        customer_id VARCHAR(255) NOT NULL,
        item_id     VARCHAR(255) NOT NULL,
        quantity    INTEGER      NOT NULL,
        unit_price  INTEGER      NOT NULL,
        PRIMARY KEY (customer_id, item_id)
    );
  SQL
}

resource "aws_cloudwatch_log_group" "database_init" {
  count = var.database_init.enabled ? 1 : 0

  name              = "/ecs/${var.name_prefix}/db-init"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_ecs_task_definition" "database_init" {
  count = var.database_init.enabled ? 1 : 0

  family                   = "${var.name_prefix}-db-init"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "db-init"
      image     = "postgres:16-alpine"
      essential = true
      command = [
        "sh",
        "-c",
        "cat > /tmp/init.sql <<'SQL'\n${local.database_init_sql}\nSQL\nfor i in $(seq 1 12); do psql -v ON_ERROR_STOP=1 -v app_user=\"$PGUSER\" -f /tmp/init.sql && exit 0; echo \"Waiting for PostgreSQL to accept connections... attempt $i/12\"; sleep 10; done; exit 1"
      ]
      environment = [
        {
          name  = "PGHOST"
          value = var.database_init.host
        },
        {
          name  = "PGPORT"
          value = var.database_init.port
        },
        {
          name  = "PGUSER"
          value = var.database_init.username
        },
        {
          name  = "PGDATABASE"
          value = var.database_init.initial_database
        },
        {
          name  = "PGSSLMODE"
          value = "require"
        }
      ]
      secrets = [
        {
          name      = "PGPASSWORD"
          valueFrom = var.database_init.password_secret_value_from
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.database_init[0].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "db-init"
        }
      }
    }
  ])

  tags = var.tags
}

resource "terraform_data" "database_init" {
  count = var.database_init.enabled ? 1 : 0

  input = {
    cluster_arn         = aws_ecs_cluster.this.arn
    task_definition_arn = aws_ecs_task_definition.database_init[0].arn
    subnets             = var.private_subnet_ids
    security_group_id   = var.security_group_id
    database_host       = var.database_init.host
    database_port       = var.database_init.port
    databases           = var.database_init.databases
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-BASH
      set -euo pipefail

      task_arn=$(aws ecs run-task \
        --region '${var.aws_region}' \
        --cluster '${aws_ecs_cluster.this.arn}' \
        --launch-type FARGATE \
        --task-definition '${aws_ecs_task_definition.database_init[0].arn}' \
        --network-configuration 'awsvpcConfiguration={subnets=[${join(",", var.private_subnet_ids)}],securityGroups=[${var.security_group_id}],assignPublicIp=DISABLED}' \
        --query 'tasks[0].taskArn' \
        --output text)

      if [ "$task_arn" = "None" ] || [ -z "$task_arn" ]; then
        echo "No se pudo iniciar la task de inicializacion de PostgreSQL."
        exit 1
      fi

      aws ecs wait tasks-stopped \
        --region '${var.aws_region}' \
        --cluster '${aws_ecs_cluster.this.arn}' \
        --tasks "$task_arn"

      exit_code=$(aws ecs describe-tasks \
        --region '${var.aws_region}' \
        --cluster '${aws_ecs_cluster.this.arn}' \
        --tasks "$task_arn" \
        --query 'tasks[0].containers[0].exitCode' \
        --output text)

      if [ "$exit_code" != "0" ]; then
        reason=$(aws ecs describe-tasks \
          --region '${var.aws_region}' \
          --cluster '${aws_ecs_cluster.this.arn}' \
          --tasks "$task_arn" \
          --query 'tasks[0].containers[0].reason' \
          --output text)
        echo "La task de inicializacion de PostgreSQL fallo con exit code $exit_code: $reason"
        exit 1
      fi
    BASH
  }
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

  dynamic "deployment_configuration" {
    for_each = var.deployment_hook.enabled ? [1] : []

    content {
      strategy = "ROLLING"

      lifecycle_hook {
        hook_target_arn = var.deployment_hook.function_arn
        role_arn        = var.deployment_hook.role_arn
        lifecycle_stages = [
          "POST_SCALE_UP",
        ]
        hook_details = jsonencode({
          port          = each.value.port
          healthPath    = each.value.validation.health_path
          expectedBody  = each.value.validation.expected_body
          smokePaths    = each.value.validation.smoke_paths
          maxAttempts   = var.deployment_hook.max_attempts
          callbackDelay = var.deployment_hook.retry_delay_seconds
          timeoutMs     = var.deployment_hook.request_timeout_ms
        })
      }
    }
  }

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

  depends_on = [terraform_data.database_init]

  tags = var.tags
}
