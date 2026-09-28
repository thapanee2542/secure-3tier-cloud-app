variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "secure-3tier-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "Secure 3-Tier Cloud App"
    Environment = "development"
    Terraform   = "true"
  }
}

# ===== VPC & NETWORKING =====
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1 (AZ a)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2 (AZ b)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound internet access (costs money, not needed for this app)"
  type        = bool
  default     = false
}

# ===== LAMBDA =====
variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

variable "lambda_log_retention_days" {
  description = "CloudWatch log retention for Lambda in days"
  type        = number
  default     = 7
}

# ===== S3 & CLOUDFRONT =====
variable "s3_log_retention_days" {
  description = "S3 access log retention in days"
  type        = number
  default     = 7
}

variable "cloudfront_log_retention_days" {
  description = "CloudFront log retention in days"
  type        = number
  default     = 7
}

variable "cloudfront_default_ttl" {
  description = "Default TTL for CloudFront in seconds"
  type        = number
  default     = 3600
}

variable "cloudfront_max_ttl" {
  description = "Maximum TTL for CloudFront in seconds"
  type        = number
  default     = 86400
}

# ===== DYNAMODB =====
variable "members_table_billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "members_table_stream_specification" {
  description = "Enable DynamoDB Streams"
  type        = bool
  default     = false
}

# ===== CORS & API =====
variable "cors_allow_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["http://localhost:5173"]
}

variable "api_gateway_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

# ===== ADDITIONAL CONFIGURATION =====
variable "enable_detailed_monitoring" {
  description = "Enable more detailed CloudWatch monitoring (may increase costs)"
  type        = bool
  default     = false
}
