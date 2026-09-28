# Secure 3-Tier Cloud App

A production-ready, serverless web application demonstrating modern cloud security best practices. This classroom project implements a three-tier architecture on AWS with infrastructure as code (Terraform), showcasing secure networking, least-privilege access, and cost-optimized design.

**Team:** KMUTNB Cloud Security - Group 1  
**Status:** Development  
**Last Updated:** January 2024

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Getting Started](#getting-started)
4. [Local Development](#local-development)
5. [Deployment to AWS](#deployment-to-aws)
6. [First-Time Deployment Walkthrough](#first-time-deployment-walkthrough)
7. [Configuration](#configuration)
8. [Testing](#testing)
9. [Troubleshooting](#troubleshooting)
10. [Backup & Recovery](#backup--recovery)
11. [Cost Analysis](#cost-analysis)
12. [Cleanup](#cleanup)

---

## Project Overview

This project consists of:

- **Frontend:** A modern React + Vite + TypeScript website displaying team member profiles
- **Backend:** Python Lambda function serving a REST API for member data
- **Database:** DynamoDB table storing member information
- **CDN:** CloudFront distribution serving static content and photos with HTTPS
- **Networking:** Private VPC with Lambda in multiple AZs, no internet gateway or NAT
- **Infrastructure:** 100% Infrastructure as Code using Terraform

### Key Features

✅ **Local Development** - Works offline without AWS credentials  
✅ **Secure by Default** - Private Lambda, block public S3 access, least-privilege IAM  
✅ **Cost-Optimized** - Uses free tier services, minimal logging, pay-per-request pricing  
✅ **High Availability** - Lambda and database across two Availability Zones  
✅ **Monitoring** - CloudWatch logs and metrics with cost-conscious alarms  
✅ **Infrastructure as Code** - 100% reproducible deployments with Terraform  
✅ **Production-Ready** - Proper error handling, CORS, caching strategies  

### Architecture Map from Diagram to Code

The diagram shows a three-tier serverless architecture:

| Tier | AWS Service | Terraform Module | Code Location |
|------|-------------|-----------------|---|
| **Web Tier** | CloudFront + S3 | `storage.tf` | `infra/storage.tf` |
| **App Tier** | API Gateway + Lambda | `compute.tf` | `infra/compute.tf`, `lambda/` |
| **Network** | VPC, Subnets, Endpoints | `networking.tf` | `infra/networking.tf` |
| **Data Tier** | DynamoDB | `database.tf` | `infra/database.tf` |
| **Security** | IAM, Security Groups | `security.tf` | `infra/security.tf` |

---

## Architecture

### 3-Tier Serverless Design

```
┌─────────────────────────────────────────────────────────────┐
│                      WEB TIER                               │
│  Browser → CloudFront HTTPS → S3 (Private, Block Public)   │
│           React Build + Member Photos                       │
└─────────────────────────────────────────────────────────────┘
                           ↓ HTTPS
┌─────────────────────────────────────────────────────────────┐
│                   APPLICATION TIER                          │
│           API Gateway HTTP API → Lambda                     │
│              GET /members → JSON Response                   │
└─────────────────────────────────────────────────────────────┘
                    ↓ (VPC Only)
┌─────────────────────────────────────────────────────────────┐
│              PRIVATE NETWORK (VPC)                          │
│   Lambda (2 AZs) ←→ VPC Endpoints for DynamoDB & S3        │
│   - Private Subnets: 10.0.1.0/24, 10.0.2.0/24             │
│   - No NAT Gateway (no internet cost)                       │
│   - Security Groups restrict traffic                        │
└─────────────────────────────────────────────────────────────┘
                    ↓ (VPC Endpoint)
┌─────────────────────────────────────────────────────────────┐
│                    DATA TIER                                │
│     DynamoDB Members Table (Encrypted, PITR enabled)       │
│     Attributes: id, name, role, bio, photoKey              │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Browser Request:** User visits CloudFront URL
2. **Static Content:** JavaScript, CSS, HTML cached in CloudFront
3. **Member Photos:** `/photos/*` served from S3 through CloudFront
4. **Member API:** React calls `GET /members` on API Gateway
5. **Lambda Processing:** Lambda reads DynamoDB using VPC endpoint
6. **URL Generation:** Lambda builds CloudFront URLs for photos
7. **Response:** JSON returned with `photoUrl` pointing to CloudFront

### Security Design

| Component | Security Controls |
|-----------|-------------------|
| **S3 Bucket** | Block all public access enabled, OAC restricts to CloudFront only |
| **CloudFront** | HTTPS only, no HTTP, security headers, compression |
| **Lambda** | Runs in private subnets, no inbound access, minimal IAM permissions |
| **API Gateway** | Public HTTPS endpoint, CORS configured for frontend origin |
| **DynamoDB** | Encryption at rest (AES-256), VPC endpoint prevents internet routing |
| **VPC Endpoints** | Gateway endpoints for free (no hourly charges) |
| **Network** | No internet navigation for Lambda, no NAT Gateway |

### Cost-Saving Design Decisions

| Decision | Reason | Savings |
|----------|--------|---------|
| **No NAT Gateway** | Lambda doesn't need internet | ~$32/month |
| **No Interface VPC Endpoints** | Gateway endpoints sufficient | ~$7/endpoint/month |
| **PAY_PER_REQUEST Billing** | Low/unpredictable traffic | vs ~$50/month provisioned |
| **No CloudWatch Logs VPC Endpoint** | Lambda can push logs via gateway | ~$7/month |
| **Local state file** | Classroom project, simple | vs ~$0.50/month for S3 backend |
| **Short log retention** | 7 days instead of 30 | Minimal reduction |

---

## Getting Started

### Prerequisites

- **Node.js** 18+ (for React frontend)
- **Python** 3.9+ (for Lambda functions and scripts)
- **AWS CLI** 2.0+ (for deployment)
- **Terraform** 1.0+ (for infrastructure)
- **Git** (for version control)
- **macOS/Linux/WSL** (Windows: use WSL2)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd secure-3tier-cloud-app
   ```

2. **Install frontend dependencies:**
   ```bash
   npm install
   ```

3. **Create environment file (optional for local development):**
   ```bash
   # For local development, this is optional
   # The app works without .env.local using default settings
   cp .env.example .env.local
   
   # Edit if needed:
   # VITE_DATA_MODE=local  (default)
   # VITE_CLOUDFRONT_DOMAIN=  (left empty for local development)
   ```

4. **Verify Python setup:**
   ```bash
   python3 --version  # Should be 3.9+
   ```

---

## Local Development

### Running the Development Server

**Start the Vite development server:**

```bash
npm run dev
```

The app will be available at `http://localhost:5173`

**Features in local mode:**
- ✅ All member data hardcoded in `src/data/members.ts`
- ✅ Placeholder SVG images served from `public/`
- ✅ No AWS credentials required
- ✅ Works completely offline
- ✅ Hot module reloading for development
- ✅ TypeScript type checking

### Local Mode Architecture

When `VITE_DATA_MODE=local` (default):

```
React App
  ↓
getMembers() in dataAccess.ts
  ↓
Loads LOCAL_MEMBERS from src/data/members.ts
  ↓
Returns members with photoUrl = "/placeholder-member-*.jpg"
  ↓
Renders with images from /public directory
```

### Customizing Member Data

**To change member information edit `src/data/members.ts`:**

```typescript
export const LOCAL_MEMBERS: Member[] = [
  {
    id: 'member-001',
    name: 'Your Name',           // Change this
    role: 'Your Role',           // Change this
    bio: 'Your bio...',          // Change this
    photoKey: 'photos/your-photo.jpg',  // For future AWS deployment
    photoUrl: '/your-image.jpg'  // Local image path
  },
  // ... more members
]
```

### Using Custom Images

**To use your own images locally:**

1. Add images to `public/` folder (e.g., `public/alice.jpg`)
2. Update `photoUrl` in `LOCAL_MEMBERS` to match:
   ```typescript
   photoUrl: '/alice.jpg'  // Relative to public/
   ```
3. Images should be 280×280px or larger
4. Supported formats: JPG, PNG, WebP

### Building for Production

**Create an optimized production build:**

```bash
npm run build
```

This creates:
- `dist/` folder with optimized, minified assets
- `dist/index.html` - entry point
- `dist/assets/` - JavaScript and CSS bundles

**Verify build:**
```bash
npm run preview  # Previews the production build locally
```

### Type Checking

**Run TypeScript type checker:**

```bash
npm run lint  # Checks for type errors without compiling
```

Fix any errors before deployment to AWS.

---

## Deployment to AWS

### Prerequisites for AWS Deployment

1. **AWS Account** with Free Tier eligibility
2. **AWS Credentials** configured locally
3. **AWS CLI** configured (`aws configure`)
4. **Terraform** installed

### AWS Credentials Setup

**Configure AWS credentials securely:**

```bash
# Option 1: Interactive configuration
aws configure
# Enter Access Key ID, Secret Access Key, region (us-east-1), format (json)

# Option 2: Using environment variables
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: Using AWS CLI profiles
aws configure --profile secure-app
export AWS_PROFILE=secure-app

# Verify configuration
aws sts get-caller-identity
```

**⚠️ SECURITY REMINDER:**
- Never commit AWS credentials to Git
- Use IAM users, never root credentials
- Enable MFA on AWS account
- Rotate access keys regularly
- Use `.env` files (in .gitignore) for local development

### First-Time Deployment Walkthrough

Follow this exact sequence for your first deployment:

#### Step 1: Build React Frontend

```bash
npm install
npm run build
ls -la dist/  # Verify dist/ folder exists
```

Output:
- `dist/index.html`
- `dist/assets/index-*.js`
- `dist/assets/index-*.css`

#### Step 2: Build Lambda Deployment Package

```bash
cd lambda
chmod +x build.sh
./build.sh
ls -la lambda_deployment.zip  # Verify zip file exists
cd ..
```

#### Step 3: Configure Terraform

```bash
cd infra

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars to customize:
# - AWS region (us-east-1 is free tier eligible)
# - Project name
# - Network CIDR blocks
# - Lambda configuration
nano terraform.tfvars  # or your preferred editor
```

**Important CORS Configuration in terraform.tfvars:**

```hcl
cors_allow_origins = [
  "http://localhost:5173",           # Local development
  "https://YOUR_CLOUDFRONT_DOMAIN"   # Will update after first deployment
]
```

#### Step 4: Initialize Terraform

```bash
terraform init
```

Output:
```
Initializing the backend...
Initializing provider plugins...
✓ terraform has been successfully configured!
```

#### Step 5: Validate Terraform Configuration

```bash
terraform validate
terraform fmt  # Auto-format files
```

#### Step 6: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the output carefully:
- Check resource count (~20-25 resources)
- Verify naming (should use project name)
- Ensure correct AWS region
- Check for any errors

#### Step 7: Apply Terraform

```bash
terraform apply tfplan
```

This will:
- Create VPC, subnets, security groups (~2-3 minutes)
- Create S3 bucket, CloudFront distribution (~3-5 minutes)
- Create Lambda, API Gateway (~1-2 minutes)
- Create DynamoDB table (instant)
- Total time: ~10 minutes

**SAVE THE OUTPUTS:**
```bash
terraform output -json > deployment-output.json
terraform output -raw cloudfront_domain_name  # Save this URL
terraform output -raw s3_bucket_name          # Save this bucket name
terraform output -raw dynamodb_table_name     # Save this table name
terraform output -raw cloudfront_distribution_id  # Save for invalidations
```

#### Step 8: Upload React Build to S3

Get the S3 bucket name from Terraform outputs:

```bash
S3_BUCKET=$(terraform output -raw s3_bucket_name)
cd ..  # Back to project root
aws s3 sync dist/ s3://$S3_BUCKET/ --delete --region us-east-1
```

Verify upload:
```bash
aws s3 ls s3://$S3_BUCKET/ --recursive --region us-east-1
```

#### Step 9: Upload Member Photos to S3

```bash
aws s3 cp public/placeholder-member-*.jpg s3://$S3_BUCKET/photos/ --region us-east-1
```

Verify upload:
```bash
aws s3 ls s3://$S3_BUCKET/photos/ --region us-east-1
```

#### Step 10: Seed DynamoDB with Member Data

```bash
TABLE=$(terraform output -raw dynamodb_table_name)
python3 scripts/seed-dynamodb.py --table-name $TABLE --region us-east-1 --use-sample
```

Verify data in DynamoDB:
```bash
aws dynamodb scan --table-name $TABLE --region us-east-1 --max-items 5
```

#### Step 11: Verify Lambda Function

Test the Lambda function directly:

```bash
aws lambda invoke \
  --function-name secure-3tier-app-dev-members-api \
  --region us-east-1 \
  /tmp/lambda-response.json \
  && cat /tmp/lambda-response.json | jq .
```

Expected response:
```json
{
  "statusCode": 200,
  "body": "{\"success\": true, \"data\": [...], \"timestamp\": \"...\"}"
}
```

#### Step 12: Test API Gateway Endpoint

Get the API endpoint from Terraform:

```bash
API_URL=$(terraform output -raw api_gateway_endpoint)
curl -X GET "$API_URL/members" \
  -H "Content-Type: application/json" \
  | jq .
```

Expected response:
```json
{
  "success": true,
  "data": [
    {
      "id": "member-001",
      "name": "Alice Johnson",
      "role": "Project Lead & Full-Stack Engineer",
      "photoUrl": "https://d123abc.cloudfront.net/photos/alice-johnson.jpg"
    }
  ]
}
```

#### Step 13: Invalidate CloudFront Cache

```bash
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*" \
  --region us-east-1
```

Wait 1-2 minutes for invalidation to complete.

#### Step 14: Visit the Website

Get the CloudFront URL:

```bash
terraform output -raw cloudfront_domain_name
```

Visit in browser (may take 2-3 minutes for first load):
- `https://YOUR_CLOUDFRONTDOMAIN`

Verify:
- ✓ Page loads with HTTPS
- ✓ Team member cards display
- ✓ Images load (placeholder SVGs or real photos)
- ✓ Architecture section visible
- ✓ No security warnings

### Deployment Complete! 🎉

You now have:
- ✅ Serverless website running on AWS
- ✅ Three-tier architecture deployed
- ✅ Private networking with Lambda in VPC
- ✅ DynamoDB storing member data
- ✅ CloudFront CDN serving content
- ✅ Monitoring and logging enabled
- ✅ Fully reproducible with Terraform

---

## Configuration

### Environment Variables

#### Local Development (.env.local)

```bash
# Data source: local or api
VITE_DATA_MODE=local

# API endpoint (only used when VITE_DATA_MODE=api)
VITE_API_BASE_URL=http://localhost:3000

# CloudFront domain (only used in production)
VITE_CLOUDFRONT_DOMAIN=

# CORS origin (usually autodetected)
VITE_CORS_ORIGIN=http://localhost:5173
```

#### AWS Deployment (.env for frontend)

After deploying to AWS, set these environment variables:

```bash
# Switch to API mode to call deployed backend
VITE_DATA_MODE=api

# API Gateway endpoint from Terraform output
VITE_API_BASE_URL=https://abc123.execute-api.us-east-1.amazonaws.com/prod

# CloudFront domain for image CDN
VITE_CLOUDFRONT_DOMAIN=https://d123abc.cloudfront.net

# Your website's origin (for CORS)
VITE_CORS_ORIGIN=https://d123abc.cloudfront.net
```

### TODO(CLOUD) Markers

The following locations need updates when deploying to AWS:

#### 1. Frontend API Configuration
**File:** `src/data/dataAccess.ts`

```typescript
// TODO(CLOUD): Replace with deployed API Gateway endpoint
const apiUrl = getApiBaseUrl()  // Currently: http://localhost:3000
// After deploy: https://abc123.execute-api.us-east-1.amazonaws.com/prod
```

**Action:** Update `VITE_API_BASE_URL` in environment variables after API deployment.

#### 2. CloudFront Image URLs
**File:** `src/data/dataAccess.ts`

```typescript
// TODO(CLOUD): Images switch from local /public to CloudFront CDN
// Local: photoUrl = '/placeholder-member-1.jpg'
// Deployed: photoUrl = 'https://d123abc.cloudfront.net/photos/alice-johnson.jpg'
```

**Action:** Lambda automatically generates CloudFront URLs. Update `VITE_CLOUDFRONT_DOMAIN`.

#### 3. Lambda Configuration
**File:** `infra/monitoring.tf` and `infra/security.tf`

```terraform
# TODO(CLOUD): Update CORS origin in Lambda for production domain
cors_allow_origins = ["http://localhost:5173"]  # Local
# After deploy: ["https://YOUR_CLOUDFRONT_DOMAIN"]
```

**Action:** After CloudFront URL is known, update in `terraform.tfvars`, re-run `terraform apply`.

#### 4. Terraform Backend
**File:** `infra/main.tf`

```terraform
# TODO(CLOUD): For production, use S3 backend with state locking:
# backend "s3" {
#   bucket         = "your-terraform-state-bucket"
#   key            = "secure-3tier-app/terraform.tfstate"
#   region         = "us-east-1"
#   encrypt        = true
#   dynamodb_table = "terraform-locks"
# }
```

**Action:** For real production, set up remote state backend. Locally, using state file is acceptable.

### Terraform Variables

Key variables in `infra/variables.tf`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `aws_region` | us-east-1 | AWS region (must be free tier eligible) |
| `project_name` | secure-3tier-app | Prefix for all resource names |
| `vpc_cidr` | 10.0.0.0/16 | VPC CIDR block |
| `lambda_memory_size` | 256 MB | Lambda memory (affects CPU) |
| `lambda_timeout` | 30 sec | Lambda max execution time |
| `members_table_billing_mode` | PAY_PER_REQUEST | DynamoDB billing (cost optimized) |
| `cors_allow_origins` | ["http://localhost:5173"] | CORS origins |
| `enable_nat_gateway` | false | NAT Gateway (disable for cost) |

---

## Testing

### Local Testing

#### Test Member Data Loading

```bash
npm run dev
# Open http://localhost:5173
# Verify member cards load
# Check browser console for errors (F12)
```

#### Test TypeScript Compilation

```bash
npm run lint
# Should show 0 errors
```

#### Test Production Build

```bash
npm run build
npm run preview
# Visit http://localhost:4173
# Verify site works exactly like dev server
```

### API Testing (Local)

#### Start a local mock API

For testing API mode without deployment, use a simple server:

```bash
# Option 1: Use the existing Lambda locally with SAM or sam-cli
# (Advanced, skip for classroom)

# Option 2: Create a simple mock server
python3 -c "
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/members':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {
                'success': True,
                'data': [
                    {'id': 'test-001', 'name': 'Test Member', 'photoUrl': '/test.jpg'}
                ]
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

HTTPServer(('localhost', 3000), Handler).serve_forever()
" &

# Update .env.local
export VITE_DATA_MODE=api
export VITE_API_BASE_URL=http://localhost:3000

# Run frontend in another terminal
npm run dev
```

### API Testing (Deployed)

#### Test with curl

```bash
API_URL="https://abc123.execute-api.us-east-1.amazonaws.com/prod"

curl -X GET "$API_URL/members" \
  -H "Content-Type: application/json" \
  -v  # Verbose output
```

Check response:
- ✓ Status 200 (not 403 or 404)
- ✓ JSON body with members array
- ✓ Each member has required fields
- ✓ photoUrl starts with CloudFront domain

#### Test with postman

1. Import API endpoint
2. Create request: `GET /members`
3. Check response status and body
4. Verify CORS headers in response

#### Test CORS

```bash
# Should include CORS headers
curl -i -X OPTIONS "$API_URL/members" \
  -H "Origin: https://d123abc.cloudfront.net" \
  -H "Access-Control-Request-Method: GET"

# Look for:
# Access-Control-Allow-Origin: https://d123abc.cloudfront.net
# Access-Control-Allow-Methods: GET, OPTIONS
```

### CloudFront Testing

#### Verify Cache Hit Rate

```bash
DIST_ID=$(terraform output -raw cloudfront_distribution_id)

aws cloudfront get-distribution-statistics \
  --distribution-id $DIST_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S.000Z) \
  --statistics BytesDonwnloaded \
  --granularity hourly
```

#### Test Image Loading Through CloudFront

```bash
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)

# Test HTML file
curl -I "$CLOUDFRONT_URL/index.html"

# Test JavaScript
curl -I "$CLOUDFRONT_URL/assets/index-*.js"

# Test image
curl -I "$CLOUDFRONT_URL/photos/placeholder-member-1.jpg"

# Verify headers:
# - Cache-Control: public, max-age=...
# - Via: cloudfront
# - X-Cache: Hit from cloudfront
```

### Lambda Testing

#### View logs in CloudWatch

```bash
# Get log group name
LOG_GROUP="/aws/lambda/secure-3tier-app-dev-members-api"

# Tail logs
aws logs tail $LOG_GROUP --follow --region us-east-1
```

#### Check for errors

```bash
# Query logs for errors
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "ERROR" \
  --region us-east-1
```

### DynamoDB Testing

#### Scan table

```bash
TABLE=$(terraform output -raw dynamodb_table_name)

aws dynamodb scan \
  --table-name $TABLE \
  --region us-east-1 \
  | jq '.Items[] | {id, name, role}'
```

#### Get single item

```bash
aws dynamodb get-item \
  --table-name $TABLE \
  --key '{"id": {"S": "member-001"}}' \
  --region us-east-1 \
  | jq '.Item'
```

#### Put test item

```bash
aws dynamodb put-item \
  --table-name $TABLE \
  --item '{
    "id": {"S": "test-migration"},
    "name": {"S": "Migration Test"},
    "role": {"S": "Testing"},
    "bio": {"S": "Testing the migration process"},
    "photoKey": {"S": "photos/test.jpg"}
  }' \
  --region us-east-1
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: "npm: command not found"

**Cause:** Node.js is not installed  
**Solution:**
```bash
# Install Node.js from https://nodejs.org (LTS version)
# Or using homebrew (macOS/Linux):
brew install node

# Verify installation
node --version  # Should be 18+
npm --version
```

#### Issue: "Cannot find module 'react'"

**Cause:** Dependencies not installed  
**Solution:**
```bash
npm install
```

#### Issue: "Build fails with TypeScript errors"

**Cause:** Type errors in code  
**Solution:**
```bash
# Check errors
npm run lint

# Fix common errors
# - Add type annotations: : Type
# - Use proper import paths
# - Check null safety with optional chaining (?.)

# Try build again
npm run build
```

#### Issue: "S3: AccessDenied when uploading"

**Cause:** AWS credentials don't have S3 permissions  
**Solution:**
```bash
# Verify credentials
aws sts get-caller-identity

# Check S3 bucket access
aws s3 ls s3://YOUR_BUCKET_NAME/

# If denied, IAM user needs s3:GetObject and s3:PutObject
# permissions on the bucket
```

#### Issue: "CloudFront returns 403 Forbidden for index.html"

**Cause:** Content not uploaded or OAC not configured correctly  
**Solution:**
1. Verify files uploaded to S3:
   ```bash
   aws s3 ls s3://YOUR_BUCKET_NAME/ --recursive
   ```

2. Check S3 bucket policy:
   ```bash
   aws s3api get-bucket-policy --bucket YOUR_BUCKET_NAME
   # Should show OAC restriction
   ```

3. Verify CloudFront OAC is attached:
   ```bash
   aws cloudfront get-distribution --id YOUR_DIST_ID \
     | jq '.Distribution.DistributionConfig.Origins[0]'
   ```

4. Create invalidation:
   ```bash
   aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
   ```

5. Wait 2-3 minutes and retry

#### Issue: "Lambda returns 502 Bad Gateway"

**Cause:** Lambda error or VPC misconfiguration  
**Solution:**
1. Check Lambda logs:
   ```bash
   aws logs tail /aws/lambda/secure-3tier-app-dev-members-api --follow
   ```

2. Verify environment variables:
   ```bash
   aws lambda get-function-configuration --function-name \
     secure-3tier-app-dev-members-api | jq '.Environment'
   ```

3. Check DynamoDB table exists:
   ```bash
   aws dynamodb describe-table --table-name Members
   ```

4. Test Lambda directly:
   ```bash
   aws lambda invoke --function-name secure-3tier-app-dev-members-api \
     /tmp/response.json && cat /tmp/response.json
   ```

#### Issue: "DynamoDB returns ValidationException"

**Cause:** Table doesn't exist or malformed request  
**Solution:**
```bash
# Verify table exists
aws dynamodb list-tables

# Verify table structure
aws dynamodb describe-table --table-name YOUR_TABLE_NAME

# Check data in table
aws dynamodb scan --table-name YOUR_TABLE_NAME --limit 5
```

#### Issue: "API Gateway returns 404 for /members"

**Cause:** Route not created or API not fully deployed  
**Solution:**
```bash
# Verify API exists and routes are configured
aws apigatewayv2 get-api --api-id YOUR_API_ID

# Verify route exists
aws apigatewayv2 get-routes --api-id YOUR_API_ID \
  | jq '.Items[] | select(.RouteKey | contains("members"))'

# Re-run terraform apply to ensure routes exist
cd infra && terraform apply
```

#### Issue: "CORS error in browser console"

**Cause:** Frontend origin not in allowed CORS origins  
**Solution:**
1. Check Lambda environment variable:
   ```bash
   aws lambda get-function-configuration \
     --function-name secure-3tier-app-dev-members-api \
     | jq '.Environment.Variables.CORS_ORIGIN'
   ```

2. Update terraform.tfvars with correct origin:
   ```hcl
   cors_allow_origins = ["https://YOUR_CLOUDFRONT_DOMAIN"]
   ```

3. Re-deploy:
   ```bash
   cd infra && terraform apply
   ```

#### Issue: "Terraform plan shows 0 changes but infrastructure missing"

**Cause:** State file out of sync with AWS  
**Solution:**
```bash
# Check state file location
terraform show

# Refresh state
terraform refresh

# Re-create missing resources
terraform apply

# To debug, check state file
cat terraform.tfstate | jq '.resources[] | .type'
```

#### Issue: "Permission denied" when running scripts

**Cause:** Script files not executable  
**Solution:**
```bash
chmod +x lambda/build.sh
chmod +x scripts/seed-dynamodb.py
chmod +x scripts/deploy.sh
chmod +x scripts/upload-artifacts.sh
```

#### Issue: Python script shows "No module named 'boto3'"

**Cause:** boto3 not installed  
**Solution:**
```bash
pip install boto3  # Or pip3 on macOS
```

#### Issue: "Terraform: Access Denied: User is not authorized"

**Cause:** AWS credentials don't have required IAM permissions  
**Solution:**
1. Verify credentials:
   ```bash
   aws sts get-caller-identity
   ```

2. Ensure user has these IAM permissions:
   - ec2:* (VPC, subnets, security groups)
   - s3:* (S3 bucket)
   - lambda:* (Lambda function)
   - apigateway:* (API Gateway)
   - dynamodb:* (DynamoDB)
   - iam:* (IAM roles)
   - logs:* (CloudWatch)
   - cloudfront:*
   - cloudwatch:*

3. For classroom, use full `AdministratorAccess` policy (not recommended for production)

### Debug Checklist

When experiencing issues, follow this checklist:

- [ ] Verify AWS credentials: `aws sts get-caller-identity`
- [ ] Check Resource region matches `terraform.tfvars`
- [ ] Review CloudWatch Logs for error details
- [ ] Confirm all Terraform apply completed successfully
- [ ] Validate S3 bucket permissions with `aws s3 ls`
- [ ] Test API directly with curl before testing frontend
- [ ] Check CORS headers in API response
- [ ] Verify DynamoDB data was seeded
- [ ] Clear CloudFront cache with invalidation
- [ ] Try in incognito/private browser window (no cache)

---

## Backup & Recovery

### DynamoDB Backup Strategy

This project uses two backup methods:

#### 1. Point-in-Time Recovery (PITR)

**Enabled by default in `database.tf`:**
```terraform
point_in_time_recovery_specification {
  point_in_time_recovery_enabled = true
}
```

**Features:**
- Automatic backups kept for 35 days
- Can restore to any point in time within 35 days
- No additional cost for PITR
- Full table restore takes ~1-5 minutes

**Restore from PITR:**
```bash
# List backup information
aws dynamodb describe-backup \
  --table-name secure-3tier-app-dev-members

# Restore to a specific point in time
aws dynamodb restore-table-to-point-in-time \
  --source-table-name secure-3tier-app-dev-members \
  --target-table-name secure-3tier-app-dev-members-restored \
  --restore-date-time 2024-01-15T10:30:00.000000+00:00 \
  --region us-east-1
```

#### 2. On-Demand Backups

**Create manual backups:**
```bash
# Create backup
BACKUP_NAME="backup-$(date +%s)"
aws dynamodb create-backup \
  --table-name secure-3tier-app-dev-members \
  --backup-name "$BACKUP_NAME" \
  --region us-east-1

# List backups
aws dynamodb list-backups --table-name secure-3tier-app-dev-members

# Restore from backup
aws dynamodb restore-table-from-backup \
  --target-table-name secure-3tier-app-dev-members-restored \
  --backup-arn arn:aws:dynamodb:us-east-1:ACCOUNT:table/...:backup/...
```

### S3 Backup Strategy

**Versioning enabled by default:**
```terraform
versioning_configuration {
  status = "Enabled"
}
```

**Features:**
- All object versions kept
- Can restore old versions of files
- Adds ~10% to storage cost for typical workloads
- Useful for website rollback

**Restore from version:**
```bash
# List versions of a file
aws s3api list-object-versions --bucket YOUR_BUCKET --prefix dist/index.html

# Copy old version
aws s3api get-object \
  --bucket YOUR_BUCKET \
  --key dist/index.html \
  --version-id VERSION_ID \
  dist/index.html

# Or simply re-upload current build
aws s3 sync dist/ s3://YOUR_BUCKET/ --delete
```

### Lambda Code Backup

Lambda code is stored in `lambda/handler.py` in Git:
- ✓ Always committed to version control
- ✓ Can deploy any previous version
- ✓ Deployment package created from source

**Revert Lambda code:**
```bash
# Use git to go to previous version
git log lambda/handler.py  # View history

# Restore old version
git show COMMIT_HASH:lambda/handler.py > lambda/handler.py

# Rebuild and redeploy
cd lambda && ./build.sh
cd ../infra && terraform apply
```

### Terraform State Backup

**Local state file backup:**
```bash
# Backup state file
cp infra/terraform.tfstate infra/terraform.tfstate.backup.$(date +%s)

# Store in safe location (version control recommended for classroom)
git add infra/terraform.tfstate.backup*
git commit -m "State file backup before major changes"
```

**State file recovery:**
```bash
# If state corrupted, restore from backup
cp infra/terraform.tfstate.backup.TIMESTAMP infra/terraform.tfstate

# Refresh to verify
terraform refresh

# Plan to see what changed
terraform plan
```

### Disaster Recovery Procedure

**If infrastructure is accidentally destroyed:**

1. **Restore DynamoDB Table (if deleted):**
   ```bash
   # From PITR
   aws dynamodb restore-table-to-point-in-time \
     --source-table-name secure-3tier-app-dev-members \
     --target-table-name secure-3tier-app-dev-members \
     --restore-date-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S.000000+00:00)
   ```

2. **Redeploy Infrastructure:**
   ```bash
   cd infra
   terraform init
   terraform apply
   # Waits for all resources to recreate (~10 minutes)
   ```

3. **Restore Website Content:**
   ```bash
   # Re-build frontend
   npm run build
   
   # Upload to S3
   aws s3 sync dist/ s3://$(terraform output -raw s3_bucket_name)/ --delete
   aws s3 sync public/ s3://$(terraform output -raw s3_bucket_name)/photos/
   
   # Invalidate CloudFront
   DIST_ID=$(terraform output -raw cloudfront_distribution_id)
   aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
   ```

4. **Verify Deployment:**
   - Test website loads
   - Test API endpoint
   - Check CloudWatch Logs
   - Verify member data in DynamoDB

**Time to recover:** ~15-20 minutes (depends on Terraform and CloudFront)

### Costs Related to Backup

| Resource | Free Tier | Cost | Notes |
|----------|-----------|------|-------|
| **PITR (DynamoDB)** | Yes | $0.20/GB/month | Incremental, very cheap |
| **Versioning (S3)** | Partial | ~10% of storage | Small for this project |
| **Manual Snapshots (DynamoDB)** | Partial | $0.10/GB/month | After first 2TB stored |

For this classroom project, backup costs are negligible.

---

## Cost Analysis

### Pricing Breakdown

**AWS Free Tier Eligibility:** Yes (12 months)

Assumes:
- 1,000 API requests per day
- 5,000 DynamoDB operations per day
- 10 GB CloudFront transfer per month
- 100 GB S3 storage

| Service | Free Tier | Usage | Estimated Cost | Notes |
|---------|-----------|-------|-----------------|-------|
| **Lambda** | 1M requests/month, 400,000 GB-seconds | 30,000 requests/month, 5,000 GB-sec | **$0.00** | Well within free tier |
| **API Gateway** | 1M requests/month | 30,000 requests/month | **$0.00** | Well within free tier; switched from REST to HTTP API |
| **DynamoDB** | 25 RCU + 25 WCU provisioned | Pay-per-request: 150K reads, 150K writes | **$0.00-$0.50** | Depends on actual usage |
| **CloudFront** | 50 GB/month data transfer out | 10 GB/month | **$0.00-$0.75** | First 50 GB free; $0.085/GB after |
| **S3** | 5 GB storage | 100 GB (build + photos) | **$2.30** | Overages beyond free tier |
| **S3 Transfer** | Included with CloudFront | Included | **$0.00** | No S3→CloudFront charges |
| **CloudWatch Logs** | 5 GB/month ingestion | 1 GB/month (Lambda + API logs) | **$0.00** | Well within free tier |
| **CloudWatch Alarms** | 10 alarms | 6 alarms | **$0.60** | $0.10 per alarm per month |
| **VPC Endpoints** | Gateway endpoints free | 2 endpoints | **$0.00** | No hourly charges |
| **PITR Backup (DynamoDB)** | $0.20/GB/month | 0.1 GB/month | **$0.02** | Minimal for small table |
| **VPC** | Free | 1 VPC, 2 subnets | **$0.00** | No charges for basic VPC |
| **IAM** | Free | Unlimited | **$0.00** | IAM is always free |
| **Terraform State (Local)** | Free | Local file | **$0.00** | Could use S3 backend for $0.50 |

### Total Estimated Monthly Cost

**During Free Tier (12 months):** $0.00 - $0.50  
**After Free Tier:** $3.00 - $4.50

**Cost Breakdown:**
- 70% CloudFront data transfer
- 20% S3 storage
- 10% CloudWatch and backups

### Cost Optimization Strategies Already Implemented

✅ **No NAT Gateway** - Would add $32/month  
✅ **No Interface VPC Endpoints** - Would add $7-14/month each  
✅ **No Bastion Host/EC2** - Would add $10-30/month  
✅ **DynamoDB on-demand** - Better for unpredictable traffic  
✅ **HTTP API over REST API** - 50% cheaper for same functionality  
✅ **Local Terraform state** - Saves $0.50/month (classroom only)  
✅ **Short log retention** - 7 days instead of 30 days  
✅ **CloudFront default cache TTL** - Reduces repeated requests  
✅ **No paid CloudWatch monitoring** - Using built-in metrics only  

### Potential Cost Issues to Monitor

⚠️ **CloudFront invalidations:** 
- 3,000 free per month
- Additional: $0.005 per invalidation
- For classroom presentation day, cap to <100 invalidations

⚠️ **Data transfer out:**
- First 50 GB/month free
- $0.085/GB after (expensive for video/large assets)
- Solution: Optimize images, use lower resolution

⚠️ **S3 storage:**
- $0.023/GB after free tier
- With 100 images at 500KB each: ~$1.15/month
- Solution: Archive old photos, use CDN caching

⚠️ **Lambda concurrent executions:**
- If traffic suddenly spikes, Lambda scales up
- Each additional GB-second costs $0.0000167
- Solution: Add reserved concurrency if needed

### AWS Free Tier Details

**Current Free Tier (as of January 2024):**

| Service | Free Allocation | Link |
|---------|-----------------|------|
| Lambda | 1,000,000 requests + 400,000 GB-seconds | [AWS Lambda Pricing](https://aws.amazon.com/lambda/pricing/) |
| API Gateway | 1,000,000 HTTP API requests | [API Gateway Pricing](https://aws.amazon.com/api-gateway/pricing/) |
| DynamoDB | On-demand only: $1.25/mil writes, $0.25/mil reads | [DynamoDB Pricing](https://aws.amazon.com/dynamodb/pricing/) |
| CloudFront | 50 GB data transfer out | [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/) |
| S3 | 5 GB storage + 20,000 GET, 2,000 PUT requests | [S3 Pricing](https://aws.amazon.com/s3/pricing/) |
| CloudWatch | 5 GB Logs ingestion + 10 alarms | [CloudWatch Pricing](https://aws.amazon.com/cloudwatch/pricing/) |
| VPC | Free tier includes basics | [VPC Pricing](https://aws.amazon.com/vpc/pricing/) |

**⚠️ Important:** Free tier eligibility varies by AWS account type and region. Always verify current pricing before deployment.

### Budget Alert Setup

**Set AWS Budget alert (recommended):**

```bash
# Create budget via AWS Console:
# 1. Go to Billing → Budgets
# 2. Create budget: Monthly cost budget
# 3. Set to $5 (example)
# 4. Alert when:
#    - Forecasted cost exceeds $5
#    - Actual cost exceeds $2
# 5. Set email notifications

# Or via AWS CLI:
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json \
  --notifications-with-subscribers '...'
```

**⚠️ IMPORTANT:** Budget alerts do NOT automatically stop resources. They're just notifications. To prevent unexpected charges:
1. Set alerts to LOW values (e.g., $2)
2. Check regularly during Free Tier period
3. Run `terraform destroy` when done testing
4. Monitor actual AWS bills weekly

---

## Cleanup

### Destroying Infrastructure

When done with testing or ready to clean up:

**Step 1: Back up any important data**

```bash
# Export DynamoDB table
aws dynamodb scan --table-name secure-3tier-app-dev-members \
  --region us-east-1 > members-backup.json

# Download S3 contents (if needed)
aws s3 sync s3://YOUR_BUCKET/ ./s3-backup/ --region us-east-1
```

**Step 2: Empty S3 bucket (required before terraform destroy)**

```bash
S3_BUCKET=$(cd infra && terraform output -raw s3_bucket_name && cd ..)
aws s3 rm s3://$S3_BUCKET --recursive --region us-east-1
aws s3 rm s3://$S3_BUCKET-access-logs --recursive --region us-east-1
```

**Step 3: Run Terraform destroy**

```bash
cd infra
terraform destroy
```

Review resources to be deleted, then confirm with `yes`.

Terraform will:
- Delete VPC, subnets, security groups (~2-3 minutes)
- Delete S3 buckets and contents
- Delete CloudFront distribution (~40 seconds)
- Delete Lambda function
- Delete API Gateway
- Delete DynamoDB table
- Delete CloudWatch log groups
- Delete IAM roles

**Total cleanup time:** ~5-10 minutes

**Step 4: Verify cleanup**

```bash
# List remaining AWS resources (should be mostly empty)
aws ec2 describe-instances --region us-east-1

aws s3 ls

aws dynamodb list-tables --region us-east-1

aws lambda list-functions --region us-east-1
```

### Manual Cleanup (if terraform destroy doesn't work)

**If terraform destroy fails:**

```bash
# Delete resources manually via AWS CLI

# 1. Delete CloudFront distribution (takes 40 seconds)
DIST_ID=$(cd infra && terraform output -raw cloudfront_distribution_id && cd ..)
aws cloudfront delete-distribution --id $DIST_ID --etag $(aws cloudfront get-distribution --id $DIST_ID | jq -r '.ETag')

# 2. Delete S3 buckets
aws s3 rb s3://secure-3tier-app-dev-website-123456789 --force

# 3. Delete Lambda
aws lambda delete-function --function-name secure-3tier-app-dev-members-api --region us-east-1

# 4. Delete API Gateway
aws apigatewayv2 delete-api --api-id YOUR_API_ID

# 5. Delete DynamoDB
aws dynamodb delete-table --table-name secure-3tier-app-dev-members

# 6. Delete VPC
aws ec2 delete-vpc --vpc-id vpc-xxxxx
```

### Files Not Deleted

The following files remain after `terraform destroy`:

| File | Action |
|------|--------|
| `terraform.tfstate` | Delete if not needed |
| `terraform.tfstate.backup` | Delete if not needed |
| `tfplan` | Delete if not needed |
| `.terraform/` | Already ignored, can delete |
| `dist/` | Delete if not needed |
| `node_modules/` | Delete if not needed |
| `lambda/lambda_deployment.zip` | Delete if not needed |
| `.env.local` | Keep safe (local config) |

**Clean up local files:**
```bash
cd infra
rm -rf .terraform/ tfplan terraform.tfstate*
cd ..
rm -rf dist/ node_modules/
rm lambda/lambda_deployment.zip
```

### Re-deployment After Cleanup

After destroying infrastructure, you can redeploy:

```bash
# This will recreate everything
cd infra
terraform init
terraform apply

# Then repeat the first deployment steps
# (Upload artifacts, seed database, etc.)
```

---

## GitHub Actions / CI/CD (Optional)

For continuous deployment (not covered in this classroom project):

1. Create `.github/workflows/deploy.yml`
2. Add secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
3. Trigger on push to main branch
4. Auto-build, deploy, and test

See GitHub Actions documentation for details.

---

## Additional Resources

### AWS Documentation
- [Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [DynamoDB Guide](https://docs.aws.amazon.com/dynamodb/)
- [CloudFront Developer Guide](https://docs.aws.amazon.com/cloudfront/)
- [VPC and Subnets](https://docs.aws.amazon.com/vpc/)
- [S3 Best Practices](https://docs.aws.amazon.com/s3/latest/userguide/BestPractices.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

### Terraform Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)
- [State File Documentation](https://www.terraform.io/docs/language/state/)

### Security References
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- [OWASP Cloud Security](https://owasp.org/www-project-cloud-security/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)

### React & Vite
- [React Documentation](https://react.dev)
- [Vite Guide](https://vitejs.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

---

## Support & Troubleshooting

### Getting Help

1. **Check logs first:**
   ```bash
   # CloudWatch logs for Lambda
   aws logs tail /aws/lambda/secure-3tier-app-dev-members-api --follow
   
   # Check API Gateway logs
   aws logs tail /aws/apigateway/secure-3tier-app-dev-http-api --follow
   
   # Or via browser console (F12)
   ```

2. **Review Terraform state:**
   ```bash
   terraform show
   terraform graph  # Visualize dependencies
   ```

3. **Check AWS Console:**
   - Lambda → Functions → secure-3tier-app-dev-members-api
   - API Gateway → APIs → secure-3tier-app-dev-http-api
   - DynamoDB → Tables → secure-3tier-app-dev-members
   - CloudFront → Distributions

4. **Test in isolation:**
   - Test Lambda directly with AWS CLI
   - Test S3 bucket permissions
   - Test DynamoDB access with IAM debugging

5. **Create GitHub Issue** with:
   - Error message and stack trace
   - Terraform version and AWS CLI version
   - Node.js and Python versions
   - Steps to reproduce

### Contact & Contributions

- **Issues:** Create GitHub issues for bugs
- **Feature Requests:** Discuss in PR comments
- **Security Issues:** Do NOT create public issue; email maintainer privately

---

## License

This project is provided for educational purposes as part of the KMUTNB Cloud Security curriculum.

---

## Appendix: Complete First Deployment Checklist

Use this checklist for presentation day or final deployment:

### Pre-Deployment (Day Before)

- [ ] Clone fresh repository
- [ ] Run `npm install`
- [ ] Run `npm run build` successfully
- [ ] Run `npm run lint` with no errors
- [ ] Create Terraform tfvars from example
- [ ] Test local development (`npm run dev`)
- [ ] Review all TODO(CLOUD) markers

### Deployment Day

- [ ] Verify AWS credentials: `aws sts get-caller-identity`
- [ ] Build Lambda package: `cd lambda && ./build.sh`
- [ ] Terraform init: `terraform init`
- [ ] Terraform validate: `terraform validate`
- [ ] Terraform plan: `terraform plan -out=tfplan`
- [ ] Review plan output for correctness
- [ ] Terraform apply: `terraform apply tfplan` (~10 minutes)
- [ ] Save Terraform outputs to text file
- [ ] Upload React build to S3
- [ ] Upload member photos to S3
- [ ] Seed DynamoDB with member data
- [ ] Create CloudFront invalidation
- [ ] Wait 2-3 minutes for CloudFront cache
- [ ] Test website in browser
- [ ] Test API endpoint with curl
- [ ] Check CloudWatch logs for errors
- [ ] Verify team member profiles load
- [ ] Verify images display correctly
- [ ] Update documentation with actual URLs

### Presentation

- [ ] Show working website to audience
- [ ] Demonstrate API response via curl
- [ ] Show CloudWatch logs and monitoring
- [ ] Walk through Terraform code
- [ ] Explain security measures
- [ ] Explain cost optimization
- [ ] Discuss lessons learned

### Post-Presentation

- [ ] Keep infrastructure running for feedback
- [ ] Or run `terraform destroy` to cleanup
- [ ] Document any issues encountered
- [ ] Update README with lessons learned

---

**Document Version:** 1.0  
**Last Updated:** January 2024  
**Status:** Complete for classroom deployment  

Questions? Check the Troubleshooting section or review AWS documentation links above.