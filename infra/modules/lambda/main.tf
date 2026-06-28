# Empaqueta solamente el codigo de la funcion. El runtime Node.js de Lambda
# incluye AWS SDK v3; las dependencias del package.json se usan para pruebas locales.
data "archive_file" "deployment_validator" {
  type        = "zip"
  output_path = "${path.module}/deployment-validator.zip"

  source {
    filename = "handler.mjs"
    content  = file("${path.module}/src/handler.mjs")
  }

  source {
    filename = "health-check.mjs"
    content  = file("${path.module}/src/health-check.mjs")
  }
}

# Tema independiente para fallas del quality gate de despliegue.
resource "aws_sns_topic" "deployment_alerts" {
  name = "${var.name_prefix}-deployment-alerts"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "deployment_email" {
  count = var.alert_email == null || trimspace(var.alert_email) == "" ? 0 : 1

  topic_arn = aws_sns_topic.deployment_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Lambda ejecutada por ECS para validar exclusivamente las tasks de la revision nueva.
resource "aws_lambda_function" "deployment_validator" {
  function_name    = "${var.name_prefix}-deployment-validator"
  description      = "Valida la nueva revision ECS y bloquea despliegues defectuosos"
  role             = var.lab_role_arn
  handler          = "handler.handler"
  runtime          = "nodejs22.x"
  architectures    = ["x86_64"]
  filename         = data.archive_file.deployment_validator.output_path
  source_code_hash = data.archive_file.deployment_validator.output_base64sha256
  memory_size      = 256
  timeout          = 20

  environment {
    variables = {
      ALERT_TOPIC_ARN = aws_sns_topic.deployment_alerts.arn
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  tags = var.tags
}

# ECS necesita asumir un rol con lambda:InvokeFunction para ejecutar el hook.
# En laboratorios que no permiten crear IAM, se puede proporcionar uno existente
# mediante ecs_hook_role_arn, con trust para ecs.amazonaws.com.
resource "aws_iam_role" "ecs_hook" {
  count = var.ecs_hook_role_arn == null ? 1 : 0

  name = "${var.name_prefix}-ecs-deployment-hook"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ecs_hook" {
  count = var.ecs_hook_role_arn == null ? 1 : 0

  name = "invoke-deployment-validator"
  role = aws_iam_role.ecs_hook[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.deployment_validator.arn, "${aws_lambda_function.deployment_validator.arn}:*"]
    }]
  })
}

# En laboratorios sin permisos para modificar IAM, el rol existente obtiene
# acceso solamente a esta funcion mediante la policy basada en recursos.
resource "aws_lambda_permission" "existing_ecs_hook" {
  count = var.ecs_hook_role_arn == null ? 0 : 1

  statement_id  = "AllowEcsDeploymentHookRole"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deployment_validator.function_name
  principal     = var.ecs_hook_role_arn
}

locals {
  ecs_hook_role_arn = coalesce(var.ecs_hook_role_arn, try(aws_iam_role.ecs_hook[0].arn, null))
}
