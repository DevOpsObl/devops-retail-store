resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "admin_jwt" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "app" {
  name        = "${var.name_prefix}/app-secrets"
  description = "Credenciales para Retail Store"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    db_username      = var.db_username
    db_password      = random_password.db.result
    admin_username   = var.admin_username
    admin_password   = random_password.admin.result
    admin_jwt_secret = random_password.admin_jwt.result
  })
}
