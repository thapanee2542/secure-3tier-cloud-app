terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local state file for classroom project
  # TODO(CLOUD): For production, use S3 backend with state locking:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "secure-3tier-app/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Local values for resource naming and configuration
  name_prefix             = "${var.project_name}-${var.environment}"
  cloudfront_domain_url   = "https://${aws_cloudfront_distribution.cdn.domain_name}"
  api_endpoint_url        = "https://${aws_apigatewayv2_api.http_api.api_endpoint}"
  account_id              = data.aws_caller_identity.current.account_id
  aws_region              = var.aws_region
  primary_az              = data.aws_availability_zones.available.names[0]
  secondary_az            = data.aws_availability_zones.available.names[1]
}
