# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Assume Role Policy
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Policy Document
data "aws_iam_policy_document" "rds_and_secret_manager" {
  statement {
    actions = [
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "rds:DescribeDBInstances",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:*",
      "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:*",
      "arn:aws:elasticfilesystem:${var.aws_region}:${data.aws_caller_identity.current.account_id}:file-system/*",
      "arn:aws:elasticfilesystem:${var.aws_region}:${data.aws_caller_identity.current.account_id}:access-point/*"
    ]

    effect = "Allow"

  }
}

data "aws_caller_identity" "current" {}