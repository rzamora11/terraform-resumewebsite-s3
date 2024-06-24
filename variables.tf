variable "region" {
  description = "The AWS region to deploy the S3 bucket in"
  type        = string
  default     = "us-west-2"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "www.romanzamoracarreras.com"
}

variable "domain_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "www.romanzamoracarreras.com"
}

variable "website_index_document" {
  description = "The index document for the website"
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "The error document for the website"
  type        = string
  default     = "error.html"
}


resource "aws_route_53_zone" "exampleDomain" {
  name = var.domain_name
}

resource "aws_route53_record" "exampleDomain-a" {
  zone_id = aws_route53_zone.exampleDomain.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_s3_bucket.example.website_endpoint
    zone_id                = aws_s3_bucket.example.hosted_zone_id
    evaluate_target_health = true
  }
}