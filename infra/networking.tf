/**
 * NETWORKING - VPC, Subnets, and VPC Endpoints
 * 
 * Architecture:
 * - VPC: 10.0.0.0/16
 * - Private Subnet 1 (AZ-a): 10.0.1.0/24
 * - Private Subnet 2 (AZ-b): 10.0.2.0/24
 * - Lambda runs in both private subnets
 * - No NAT Gateway (cost-saving)
 * - Gateway endpoints for DynamoDB (and S3 if needed)
 */

# ===== VPC =====
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ===== PRIVATE SUBNET 1 (AZ-a) =====
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_1_cidr
  availability_zone       = local.primary_az
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-private-subnet-1"
    Tier = "Private"
  }
}

# ===== PRIVATE SUBNET 2 (AZ-b) =====
resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_2_cidr
  availability_zone       = local.secondary_az
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-private-subnet-2"
    Tier = "Private"
  }
}

# ===== ROUTE TABLES FOR PRIVATE SUBNETS =====
# Private subnets don't route to internet; only VPC endpoints

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# ===== VPC ENDPOINTS =====

# DynamoDB Gateway Endpoint
# No additional cost, no hourly charges
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${local.name_prefix}-dynamodb-endpoint"
  }
}

# S3 Gateway Endpoint
# Optional: No cost, helpful for Lambda to read/write S3
# For this project, Lambda only reads DynamoDB, but S3 endpoint can be useful
# for future features or direct Lambda access to photos in S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${local.name_prefix}-s3-endpoint"
  }
}

# Optional: Secrets Manager VPC Endpoint
# High cost ($7/month) - only enable if needed for certificate management
# Not enabled by default in this cost-conscious setup

# Optional: CloudWatch Logs VPC Endpoint
# High cost ($7/month) - not enabled by default
# Lambda can push logs directly through the gateway endpoints

# Note: Interface VPC endpoints (like EC2, StS) have hourly charges
# and are not used in this minimal serverless architecture
