/**
 * SECURITY - Security Groups and IAM Policies
 * 
 * Principle: Least privilege access
 * - Lambda security group allows no inbound, outbound to DynamoDB for VPC endpoint
 * - Lambda IAM role scoped to DynamoDB read-only operations
 * - API Gateway can invoke Lambda
 * - CloudFront can only access S3 through OAC (Origin Access Control)
 */

# ===== LAMBDA SECURITY GROUP =====
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  # Allow no inbound traffic (Lambda is invoked via API Gateway, not directly)

  # Allow outbound to VPC endpoints (DynamoDB, S3)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Only within VPC to endpoints
    description = "Allow HTTPS to VPC endpoints (DynamoDB, S3)"
  }

  # Allow DNS resolution (required for service discovery)
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow DNS queries within VPC"
  }

  tags = {
    Name = "${local.name_prefix}-lambda-sg"
  }
}

# ===== LAMBDA IAM ROLE =====
resource "aws_iam_role" "lambda_role" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-lambda-role"
  }
}

# ===== LAMBDA POLICY: VPC EXECUTION =====
# Required for Lambda to run in a VPC (manage ENIs)
resource "aws_iam_role_policy" "lambda_vpc_execution" {
  name   = "${local.name_prefix}-lambda-vpc-execution"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVPCExecution"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

# ===== LAMBDA POLICY: DYNAMODB READ-ONLY =====
resource "aws_iam_role_policy" "lambda_dynamodb_read" {
  name   = "${local.name_prefix}-lambda-dynamodb-read"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDynamoDBScan"
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeStream"
        ]
        Resource = aws_dynamodb_table.members.arn
      }
    ]
  })
}

# ===== LAMBDA POLICY: CLOUDWATCH LOGS =====
resource "aws_iam_role_policy" "lambda_logs" {
  name   = "${local.name_prefix}-lambda-logs"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.aws_region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-members-api:*"
      }
    ]
  })
}

# ===== API GATEWAY IAM ROLE =====
# Allows API Gateway to invoke Lambda

resource "aws_iam_role" "api_gateway_role" {
  name               = "${local.name_prefix}-api-gateway-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-api-gateway-role"
  }
}

resource "aws_iam_role_policy" "api_invoke_lambda" {
  name   = "${local.name_prefix}-api-invoke-lambda"
  role   = aws_iam_role.api_gateway_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.members_api.arn
      }
    ]
  })
}

# ===== CLOUDFRONT OAC (Origin Access Control) =====
# Modern replacement for OAI, allows only CloudFront to access S3

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${local.name_prefix}-s3-oac"
  description                       = "OAC for S3 website distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ===== S3 BUCKET POLICY =====
# Allow CloudFront to read objects

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${local.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"
          }
        }
      }
    ]
  })
}
