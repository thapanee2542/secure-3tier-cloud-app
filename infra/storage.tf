/**
 * STORAGE - S3 Bucket and CloudFront Distribution
 * 
 * Architecture:
 * - Private S3 bucket with Block Public Access enabled
 * - CloudFront distribution with Origin Access Control (OAC)
 * - No public website endpoint on S3
 * - All content served through CloudFront HTTPS
 * - Support for gzip compression of text assets
 */

# ===== S3 BUCKET FOR WEBSITE & PHOTOS =====
resource "aws_s3_bucket" "website" {
  bucket = "${local.name_prefix}-website-${local.account_id}"

  tags = {
    Name = "${local.name_prefix}-website"
  }
}

# Block all public access to S3 bucket
# This ensures S3 is never accidentally exposed as a public website
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for safety
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable access logging (optional, for compliance)
# Logs are stored in a separate bucket to separate concerns
resource "aws_s3_bucket" "access_logs" {
  bucket = "${local.name_prefix}-access-logs-${local.account_id}"

  tags = {
    Name = "${local.name_prefix}-access-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = var.s3_log_retention_days
    }
  }
}

# ===== CLOUDFRONT DISTRIBUTION =====
# Serves website and photos to users
# Provides HTTPS, caching, and DDoS protection

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${local.name_prefix} CDN"

  # Origin: S3 bucket
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Default behavior: HTML/JS/CSS caching
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    compress = true # Enable Gzip compression

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    default_ttl            = var.cloudfront_default_ttl
    max_ttl                = var.cloudfront_max_ttl
    min_ttl                = 0
  }

  # Cache behavior for photos: longer TTL
  cache_behavior {
    path_pattern     = "/photos/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    compress = false # Photos are already compressed

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    default_ttl            = 86400      # 24 hours
    max_ttl                = 31536000   # 1 year
    min_ttl                = 0
  }

  # Restrictions: Allow all countries
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # HTTPS certificate (AWS managed)
  viewer_certificate {
    cloudfront_default_certificate = true
    # TODO(CLOUD): For production, use your own SSL certificate:
    # acm_certificate_arn      = aws_acm_certificate.main.arn
    # ssl_support_method       = "sni-only"
    # minimum_protocol_version = "TLSv1.2_2021"
  }

  # Logging (optional, for analysis)
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.access_logs.bucket_regional_domain_name
    prefix          = "cloudfront/"
  }

  # Security headers via response headers policy
  # TODO(CLOUD): Add additional security headers:
  # - Strict-Transport-Security
  # - Content-Security-Policy
  # - X-Content-Type-Options
  # - X-Frame-Options

  tags = {
    Name = "${local.name_prefix}-cdn"
  }
}

# Invalidation for cache busting after deployments
# CloudFront invalidations can have costs depending on usage
# Free tier includes 3000 invalidation requests per month
# See: https://aws.amazon.com/cloudfront/pricing/
