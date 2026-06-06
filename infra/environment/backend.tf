terraform {
  backend "s3" {
    # Configurar con el archivo del ambiente:
    # terraform init -backend-config=backend/dev.hcl
  }
}
