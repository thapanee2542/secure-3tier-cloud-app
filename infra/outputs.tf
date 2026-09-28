/**
 * TERRAFORM OUTPUTS
 * 
 * These outputs provide important values after deployment.
 * Retrieve them with: terraform output -json
 */

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (use for frontend VITE_CLOUDFRONT_DOMAIN)"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for invalidations"
  value       = aws_cloudfront_distribution.cdn.id
}

output "api_gateway_endpoint" {
  description = "API Gateway HTTP API endpoint (use for frontend VITE_API_BASE_URL)"
  value       = "https://${aws_apigatewayv2_api.http_api.api_endpoint}"
}

output "s3_bucket_name" {
  description = "S3 bucket for website and photos"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB Members table name (for seeding data)"
  value       = aws_dynamodb_table.members.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB Members table ARN"
  value       = aws_dynamodb_table.members.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.members_api.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.members_api.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_1_id" {
  description = "Private Subnet 1 ID (AZ a)"
  value       = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  description = "Private Subnet 2 ID (AZ b)"
  value       = aws_subnet.private_2.id
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

output "cloudwatch_log_group_lambda" {
  description = "CloudWatch Log Group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "cloudwatch_log_group_api" {
  description = "CloudWatch Log Group for API Gateway"
  value       = aws_cloudwatch_log_group.api_logs.name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${local.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# ===== DEPLOYMENT INSTRUCTIONS =====
output "deployment_instructions" {
  description = "Steps for first deployment"
  value = <<-EOT
    
    === DEPLOYMENT CHECKLIST ===
    
    1. Build React frontend:
       npm install
       npm run build
       (Check that dist/ folder was created)
    
    2. Build Lambda deployment package:
       chmod +x lambda/build.sh
       ./lambda/build.sh
       (Check that lambda/lambda_deployment.zip was created)
    
    3. Upload React build to S3:
       aws s3 sync dist/ s3://$(terraform output -raw s3_bucket_name)/ --delete
    
    4. Upload member photos to S3:
       aws s3 cp public/placeholder-member-*.jpg s3://$(terraform output -raw s3_bucket_name)/photos/
    
    5. Seed DynamoDB with member data:
       python scripts/seed-dynamodb.py --table-name $(terraform output -raw dynamodb_table_name) --region ${local.aws_region}
    
    6. Invalidate CloudFront cache:
       aws cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_distribution_id) --paths "/*"
    
    7. Test the API:
       curl https://$(terraform output -raw api_gateway_endpoint)/members
    
    8. Visit the website:
       https://$(terraform output -raw cloudfront_domain_name)
    
    === CLEANUP ===
    
    To destroy all resources:
    terraform destroy
    
    Note: This does NOT delete S3 bucket contents or CloudWatch logs
    To completely remove S3 bucket, you must:
    1. Empty the S3 bucket: aws s3 rm s3://BUCKET_NAME --recursive
    2. Run terraform destroy
  EOT
}
