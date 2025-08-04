terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }
  required_version = ">= 1.6.0"

  backend "s3" {
    #   bucket         = "infrabucket-iacgitops-us-east-1"
    key    = "wordpress/terraform.tfstate"
    region = var.aws_region
    # dynamodb_table = "tfstate-dynamo-lock"
    encrypt = true
  }
}