# This file defines the input variables for the S3 module.

variable "bucket_name" {
  description = "The name of the S3 bucket to create."
  type        = string
}

variable "environment" {
  description = "The environment name for tagging purposes."
  type        = string
}