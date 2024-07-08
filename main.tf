resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.static_site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.static_site.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "public_policy" {
  depends_on = [
      aws_s3_bucket_acl.example
    ]
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.static_site.id}/*"
      }
    ]
  })
}

locals {
  files = [
    for file in fileset("website_content", "**/*") : {
      source       = "${path.module}/website_content/${file}",
      key          = file,
      content_type = lookup(local.content_type_map, split(".", file)[1], "application/octet-stream")
    }
  ]

  content_type_map = {
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "pdf"  = "application/pdf",
    "txt"  = "text/plain",
    "json" = "application/json",
    "xml"  = "application/xml",
    "ico"  = "image/x-icon",
  }
}

resource "aws_s3_object" "website_files" {
  depends_on = [
      aws_s3_bucket_acl.example
    ]
  for_each = { for file in local.files : file.key => file }

  bucket       = aws_s3_bucket.static_site.id
  key          = each.value.key
  source       = each.value.source
  acl          = "public-read"
  content_type = each.value.content_type
  etag         = filemd5(each.value.source)
}
