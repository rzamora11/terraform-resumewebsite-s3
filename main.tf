resource "aws_s3_bucket" "static_site"{
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


# Local file list function
locals {

  files = [
    for file in fileset("website_content", "**/*") : {
      source       = "${path.module}/website_content/${file}",
      key          = file,
      content_type = local.content_type_map[split(".",file)[1]]
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
    default = "application/octet-stream"
  }
}

# Iterate over the list of files and upload each one
resource "aws_s3_object" "website_files" {
  for_each = { for file in local.files : file.key => file }

  bucket       = aws_s3_bucket.static_site.id
  key          = each.value.key
  source       = each.value.source
  acl          = "public-read"
  content_type = each.value.content_type
  etag         = filemd5(each.value.source)
}


resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_s3_bucket.static_site.website_domain
    zone_id                = aws_s3_bucket.static_site.hosted_zone_id
    evaluate_target_health = false
  }
}