#!/bin/bash
# Upload frontend build and photos to S3
# 
# Usage:
#   ./scripts/upload-artifacts.sh <S3_BUCKET_NAME> [AWS_REGION]
#
# Example:
#   ./scripts/upload-artifacts.sh secure-3tier-app-dev-website-123456789 us-east-1
#

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Arguments
S3_BUCKET="${1:-}"
AWS_REGION="${2:-us-east-1}"

# Validation
if [ -z "$S3_BUCKET" ]; then
  echo "Error: S3 bucket name is required"
  echo "Usage: $0 <S3_BUCKET_NAME> [AWS_REGION]"
  echo ""
  echo "Example:"
  echo "  $0 secure-3tier-app-dev-website-123456789 us-east-1"
  exit 1
fi

echo "=========================================="
echo "Uploading Artifacts to S3"
echo "=========================================="
echo "S3 Bucket: $S3_BUCKET"
echo "Region: $AWS_REGION"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "❌ Error: AWS CLI is not installed"
  echo "Install it with: pip install awscli"
  exit 1
fi

# Check if dist directory exists
if [ ! -d "$PROJECT_DIR/dist" ]; then
  echo "❌ Error: dist/ directory not found"
  echo "Build the React app first:"
  echo "  cd $PROJECT_DIR"
  echo "  npm run build"
  exit 1
fi

# Upload React build
echo "📦 Uploading React build (dist/)..."
aws s3 sync "$PROJECT_DIR/dist/" "s3://$S3_BUCKET/" \
  --region "$AWS_REGION" \
  --delete \
  --cache-control "public, max-age=3600" \
  --exclude ".git/*" \
  --exclude "node_modules/*" \
  --exclude ".env*"

echo "✓ React build uploaded successfully"

# Upload photos
echo ""
echo "📸 Uploading member photos to s3://$S3_BUCKET/photos/..."

if [ -d "$PROJECT_DIR/public" ]; then
  # Use actual photos if they exist
  aws s3 sync "$PROJECT_DIR/public/" "s3://$S3_BUCKET/photos/" \
    --region "$AWS_REGION" \
    --exclude "*.html" \
    --exclude "*.json" \
    --cache-control "public, max-age=31536000"
  
  echo "✓ Photos uploaded successfully"
else
  echo "⚠ Warning: public/ directory not found, skipping photos"
fi

echo ""
echo "=========================================="
echo "✅ Upload complete!"
echo "=========================================="
echo ""
echo "Website will be available at:"
echo "  https://<CLOUDFRONT_DOMAIN>"
echo ""
echo "Note: CloudFront may take a few minutes to cache the new content"
echo "To force immediate update, run:"
echo "  aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths '/*'"
