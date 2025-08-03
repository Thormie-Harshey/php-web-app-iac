# This file defines the input variables for the DynamoDB module.

variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "hash_key" {
  description = "The name of the primary key for the DynamoDB table."
  type        = string
}

variable "environment" {
  description = "The environment name for tagging purposes."
  type        = string
}