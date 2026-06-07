# Backend remoto S3. Los valores concretos se pasan con backend/dev.hcl,
# backend/test.hcl o backend/prod.hcl durante terraform init.
terraform {
  backend "s3" {
    # Configurar con el archivo del ambiente:
    # terraform init -backend-config=backend/dev.hcl
  }
}
