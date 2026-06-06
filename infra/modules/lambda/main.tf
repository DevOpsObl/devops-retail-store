data "archive_file" "function" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    filename = "index.py"
    content  = <<-PY
      import json

      def handler(event, context):
          print(json.dumps({"message": "retail automation event received", "event": event}))
          return {"statusCode": 200, "body": "ok"}
    PY
  }
}

resource "aws_lambda_function" "automation" {
  function_name    = "${var.name_prefix}-automation"
  description      = "Automatizaciones operativas y de seguridad para Retail Store"
  role             = var.lab_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
  timeout          = 30

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "hourly" {
  name                = "${var.name_prefix}-automation-hourly"
  description         = "Invoca la Lambda de automatizacion cada hora"
  schedule_expression = "rate(1 hour)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.hourly.name
  target_id = "automation"
  arn       = aws_lambda_function.automation.arn
}

resource "aws_lambda_permission" "events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.automation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly.arn
}
