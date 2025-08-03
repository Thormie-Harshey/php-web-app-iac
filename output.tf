output "alb_dns_name" {
  description = "Application LoadBalancer DNS"
  value       = module.alb.alb_dns_name
}

output "iam_account_id" {
  description = "Account ID"
  value       = module.ec2.account_id
}

output "ec2_instance_id" {
  description = "Instance Id for ags instance"
  value       = module.ec2.instance_id
}

output "amazon-ami-id" {
  description = "Image ID"
  value       = module.ec2.ami_id
}

output "instance_ids_asg" {
  description = "ASG Instance Ids"
  value       = module.asg.asg_instance_id
}

output "s3_bucket_id" {
  description = "The ID of the S3 bucket created by the s3 module."
  value       = module.s3.s3_bucket_id
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table created by the dynamodb module."
  value       = module.dynamodb.dynamodb_table_name
}
