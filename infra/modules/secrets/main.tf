# Password generada para el usuario maestro de PostgreSQL.
resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Password generada para el usuario administrador de la aplicacion.
resource "random_password" "admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secreto aleatorio usado para firmar JWT del panel admin.
resource "random_password" "admin_jwt" {
  length  = 32
  special = false
}

locals {
  admin_password = var.admin_password != null && trimspace(var.admin_password) != "" ? var.admin_password : random_password.admin.result
}

# Contenedor logico del secreto en AWS Secrets Manager.
resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.name_prefix}/app-secrets"
  description             = "Credenciales para Retail Store"
  recovery_window_in_days = 0

  tags = var.tags
}

# Version actual del secreto. Se guarda como JSON para referenciar campos individuales desde ECS.
resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    db_username      = var.db_username
    db_password      = random_password.db.result
    admin_username   = var.admin_username
    admin_password   = local.admin_password
    admin_jwt_secret = random_password.admin_jwt.result
  })
}
