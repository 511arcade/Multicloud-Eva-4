# Bucket S3 para almacenamiento de objetos (documentos, recetas, respaldos).
# El enunciado pide "uso de ACL para acceso a objetos".
resource "aws_s3_bucket" "objects" {
  bucket_prefix = "${var.project_name}-objetos-"
  tags          = { Name = "${var.project_name}-objetos" }
}

# Habilitar ACLs (Object Ownership = BucketOwnerPreferred)
resource "aws_s3_bucket_ownership_controls" "objects" {
  bucket = aws_s3_bucket.objects.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "objects" {
  bucket                  = aws_s3_bucket.objects.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "objects" {
  depends_on = [
    aws_s3_bucket_ownership_controls.objects,
    aws_s3_bucket_public_access_block.objects,
  ]
  bucket = aws_s3_bucket.objects.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "objects" {
  bucket = aws_s3_bucket.objects.id
  versioning_configuration {
    status = "Enabled"
  }
}
