resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name

  website {
    index_document = var.website_index_document
    error_document = var.website_error_document
  }

  acl = "public-read"
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}