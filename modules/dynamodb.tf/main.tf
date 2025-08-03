resource "aws_dynamodb_table" "my_table" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = var.hash_key

  attribute {
    name = var.hash_key
    type = "S"  # S for String, N for Number, B for Binary
  }

  tags = {
    Name        = var.table_name
    Environment = var.environment
  }
}