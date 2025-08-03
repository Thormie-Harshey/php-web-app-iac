output "dynamodb_table_name" {
  description = "The name of the created DynamoDB table."
  value       = aws_dynamodb_table.my_table.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the created DynamoDB table."
  value       = aws_dynamodb_table.my_table.arn
}
