#!/bin/bash
# End-to-end deployment script for Secure 3-Tier Cloud App
#
# This script guides through the complete deployment process:
# 1. Build React frontend
# 2. Build Lambda deployment package
# 3. Deploy infrastructure with Terraform
# 4. Upload frontend build to S3
# 5. Upload member photos to S3
# 6. Seed DynamoDB with member data
# 7. Create CloudFront invalidation
#
# Usage:
#   ./scripts/deploy.sh [--skip-build] [--dry-run]
#

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
INFRA_DIR="$PROJECT_DIR/infra"
LAMBDA_DIR="$PROJECT_DIR/lambda"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
SKIP_BUILD=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--skip-build] [--dry-run]"
      exit 1
      ;;
  esac
done

# Functions
print_header() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

check_command() {
  if ! command -v "$1" &> /dev/null; then
    print_error "$1 is not installed"
    exit 1
  fi
}

# Verify prerequisites
print_header "Checking Prerequisites"

check_command "node"
check_command "npm"
check_command "python3"
check_command "terraform"
check_command "aws"

print_success "All prerequisites installed"

# Step 1: Build React frontend
if [ "$SKIP_BUILD" = false ]; then
  print_header "Step 1: Building React Frontend"
  
  cd "$PROJECT_DIR"
  
  if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: Would install npm dependencies"
    echo "DRY RUN: Would run: npm run build"
  else
    echo "Installing npm dependencies..."
    npm install --silent
    print_success "Dependencies installed"
    
    echo "Building React frontend..."
    npm run build
    print_success "React frontend built"
  fi
else
  print_warning "Skipping build (--skip-build)"
fi

# Step 2: Build Lambda deployment package
print_header "Step 2: Building Lambda Deployment Package"

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Would build Lambda package"
else
  cd "$LAMBDA_DIR"
  chmod +x build.sh
  ./build.sh
  print_success "Lambda deployment package ready: lambda_deployment.zip"
fi

# Step 3: Initialize and validate Terraform
print_header "Step 3: Terraform Setup"

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Would initialize Terraform"
  echo "DRY RUN: Would run: terraform validate"
else
  cd "$INFRA_DIR"
  
  # Copy example tfvars if it doesn't exist
  if [ ! -f terraform.tfvars ]; then
    if [ -f terraform.tfvars.example ]; then
      cp terraform.tfvars.example terraform.tfvars
      print_success "Created terraform.tfvars from example"
      print_warning "Please review and customize terraform.tfvars if needed"
    fi
  fi
  
  terraform init
  print_success "Terraform initialized"
  
  terraform validate
  print_success "Terraform configuration is valid"
fi

# Step 4: Plan and Apply Terraform
print_header "Step 4: Terraform Plan & Apply"

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Would run terraform plan"
  echo "DRY RUN: Would run terraform apply"
else
  cd "$INFRA_DIR"
  
  echo "Creating infrastructure plan..."
  terraform plan -out=tfplan
  
  echo ""
  print_warning "Review the Terraform plan above"
  read -p "Continue with terraform apply? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply tfplan
    print_success "Infrastructure deployed"
  else
    print_warning "Deployment cancelled"
    exit 0
  fi
fi

# Step 5: Get infrastructure outputs
print_header "Step 5: Retrieving Infrastructure Outputs"

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Would retrieve Terraform outputs"
  S3_BUCKET="YOUR_BUCKET_NAME"
  DISTRIBUTION_ID="YOUR_DISTRIBUTION_ID"
  TABLE_NAME="YOUR_TABLE_NAME"
  CLOUDFRONT_DOMAIN="YOUR_CLOUDFRONT_DOMAIN"
else
  cd "$INFRA_DIR"
  
  S3_BUCKET=$(terraform output -raw s3_bucket_name)
  DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
  TABLE_NAME=$(terraform output -raw dynamodb_table_name)
  CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)
  AWS_REGION=$(terraform output -raw -json | grep -o '"aws_region":"[^"]*' | cut -d'"' -f4 || echo "us-east-1")

  print_success "Infrastructure outputs retrieved"
fi

echo "S3 Bucket: $S3_BUCKET"
echo "Distribution ID: $DISTRIBUTION_ID"
echo "DynamoDB Table: $TABLE_NAME"
echo "CloudFront Domain: $CLOUDFRONT_DOMAIN"

# Step 6: Upload artifacts
print_header "Step 6: Uploading Artifacts to S3"

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Would upload dist/ to S3"
  echo "DRY RUN: Would upload photos to S3"
else
  cd "$PROJECT_DIR"
  
  echo "Uploading React build..."
  aws s3 sync dist/ "s3://$S3_BUCKET/" \
    --delete \
    --cache-control "public, max-age=3600"
  print_success "React build uploaded"
  
  echo "Uploading member photos..."
  aws s3 sync public/ "s3://$S3_BUCKET/photos/" \
    --cache-control "public, max-age=31536000" \
    --exclude "*.json" \
    --exclude ".gitkeep"
  print_success "Photos uploaded"
fi

# Step 7: Seed DynamoDB
print_header "Step 7: Seeding DynamoDB with Member Data"

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Would seed DynamoDB table: $TABLE_NAME"
else
  cd "$PROJECT_DIR"
  
  python3 scripts/seed-dynamodb.py \
    --table-name "$TABLE_NAME" \
    --region "${AWS_REGION:-us-east-1}" \
    --use-sample
  print_success "DynamoDB seeded with member data"
fi

# Step 8: Create CloudFront invalidation
print_header "Step 8: Invalidating CloudFront Cache"

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Would create CloudFront invalidation"
else
  echo "Creating invalidation for distribution: $DISTRIBUTION_ID"
  aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --region "${AWS_REGION:-us-east-1}"
  print_success "CloudFront cache invalidated"
fi

# Final summary
print_header "🎉 Deployment Complete!"

echo ""
echo "Website URLs:"
echo -e "  ${GREEN}Frontend: $CLOUDFRONT_DOMAIN${NC}"
echo ""
echo "API Endpoints:"
echo -e "  ${GREEN}Members API: ${CLOUDFRONT_DOMAIN%/*}/api/members${NC}"
echo ""
echo "Management URLs:"
echo -e "  ${BLUE}CloudWatch Logs: https://console.aws.amazon.com/logs${NC}"
echo -e "  ${BLUE}DynamoDB Table: https://console.aws.amazon.com/dynamodb${NC}"
echo -e "  ${BLUE}Lambda Functions: https://console.aws.amazon.com/lambda${NC}"
echo ""
echo "Next steps:"
echo "  1. Visit $CLOUDFRONT_DOMAIN to see your website"
echo "  2. Check CloudWatch logs for any issues"
echo "  3. Test the API: curl $CLOUDFRONT_DOMAIN/api/members"
echo ""
echo "To destroy all resources and cleanup:"
echo "  cd $INFRA_DIR && terraform destroy"
