resource "aws_s3_bucket" "my_bucket" {
  # The bucket name is provided as a variable from the root module.
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

