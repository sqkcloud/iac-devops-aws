terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  github_provider_url = "https://token.actions.githubusercontent.com"
  audience            = "sts.amazonaws.com"
  repo_full_name      = "${var.github_org}/${var.github_repo}"
  common_tags = merge({
    Project   = var.project_name
    ManagedBy = "Terraform"
    Stack     = "bootstrap-oidc"
  }, var.tags)
}

resource "aws_iam_openid_connect_provider" "github" {
  url = local.github_provider_url
  client_id_list = [local.audience]
  thumbprint_list = [var.github_oidc_thumbprint]
  tags = local.common_tags
}

data "aws_iam_policy_document" "assume_dev" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [local.audience]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repo_full_name}:pull_request",
        "repo:${local.repo_full_name}:ref:refs/heads/main",
        "repo:${local.repo_full_name}:environment:dev"
      ]
    }
  }
}

data "aws_iam_policy_document" "assume_stage" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [local.audience]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repo_full_name}:ref:refs/tags/release-*",
        "repo:${local.repo_full_name}:environment:stage"
      ]
    }
  }
}

data "aws_iam_policy_document" "assume_prod" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [local.audience]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repo_full_name}:environment:prod"
      ]
    }
  }
}

resource "aws_iam_role" "dev" {
  name               = "${var.project_name}-github-actions-dev"
  assume_role_policy = data.aws_iam_policy_document.assume_dev.json
  tags               = local.common_tags
}

resource "aws_iam_role" "stage" {
  name               = "${var.project_name}-github-actions-stage"
  assume_role_policy = data.aws_iam_policy_document.assume_stage.json
  tags               = local.common_tags
}

resource "aws_iam_role" "prod" {
  name               = "${var.project_name}-github-actions-prod"
  assume_role_policy = data.aws_iam_policy_document.assume_prod.json
  tags               = local.common_tags
}

locals {
  service_actions = [
    "ec2:*",
    "elasticloadbalancing:*",
    "rds:*",
    "cloudwatch:*",
    "logs:*",
    "route53:*",
    "acm:*",
    "iam:PassRole",
    "iam:GetRole",
    "iam:GetInstanceProfile",
    "iam:CreateServiceLinkedRole"
  ]
}

resource "aws_iam_role_policy" "dev_inline" {
  name = "${var.project_name}-dev-inline"
  role = aws_iam_role.dev.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Effect = "Allow",
        Action = ["s3:ListBucket", "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration"],
        Resource = ["arn:aws:s3:::${var.tf_state_bucket_dev}"]
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = ["arn:aws:s3:::${var.tf_state_bucket_dev}/*"]
      },
      {
        Effect = "Allow",
        Action = local.service_actions,
        Resource = "*"
      }
    ], var.tf_lock_table_dev_arn != "" ? [{
      Effect = "Allow",
      Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"],
      Resource = var.tf_lock_table_dev_arn
    }] : [])
  })
}

resource "aws_iam_role_policy" "stage_inline" {
  name = "${var.project_name}-stage-inline"
  role = aws_iam_role.stage.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Effect = "Allow",
        Action = ["s3:ListBucket", "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration"],
        Resource = ["arn:aws:s3:::${var.tf_state_bucket_stage}"]
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = ["arn:aws:s3:::${var.tf_state_bucket_stage}/*"]
      },
      {
        Effect = "Allow",
        Action = local.service_actions,
        Resource = "*"
      }
    ], var.tf_lock_table_stage_arn != "" ? [{
      Effect = "Allow",
      Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"],
      Resource = var.tf_lock_table_stage_arn
    }] : [])
  })
}

resource "aws_iam_role_policy" "prod_inline" {
  name = "${var.project_name}-prod-inline"
  role = aws_iam_role.prod.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Effect = "Allow",
        Action = ["s3:ListBucket", "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration"],
        Resource = ["arn:aws:s3:::${var.tf_state_bucket_prod}"]
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = ["arn:aws:s3:::${var.tf_state_bucket_prod}/*"]
      },
      {
        Effect = "Allow",
        Action = local.service_actions,
        Resource = "*"
      }
    ], var.tf_lock_table_prod_arn != "" ? [{
      Effect = "Allow",
      Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"],
      Resource = var.tf_lock_table_prod_arn
    }] : [])
  })
}
