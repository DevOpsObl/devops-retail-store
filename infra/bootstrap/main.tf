# Tags comunes aplicados a los recursos de bootstrap.
locals {
  tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "terraform"
      Scope     = "bootstrap"
    },
    var.tags
  )
}

# Bucket S3 centralizado donde Terraform almacena el estado remoto.
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = local.tags
}

# Habilita versionado para poder recuperar versiones anteriores del estado.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifra el estado en reposo usando cifrado administrado por S3.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquea cualquier exposicion publica accidental del bucket de estado.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
