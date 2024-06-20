variable "region" {
  description = "The AWS region to deploy the S3 bucket in"
  type        = string
  default     = "us-west-2"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
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