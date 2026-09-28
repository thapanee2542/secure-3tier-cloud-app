/**
 * COMPUTE - Lambda Function and API Gateway
 * 
 * Architecture:
 * - Python Lambda function running in private VPC subnets
 * - Deployed across two AZs for high availability
 * - HTTP API Gateway (newer, cheaper than REST API)
 * - No authorization for now (public endpoint)
 * TODO(CLOUD): Add authorization (API keys or custom authorizer) for production
 */

# ===== DATA ARCHIVE FOR LAMBDA =====
# Lambda code must be packaged as a zip file

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/handler.py"
  output_path = "${path.module}/lambda_deployment.zip"
}

# ===== LAMBDA FUNCTION =====
resource "aws_lambda_function" "members_api" {
  filename            = data.archive_file.lambda_zip.output_path
  source_code_hash    = data.archive_file.lambda_zip.output_base64sha256
  function_name       = "${local.name_prefix}-members-api"
  role                = aws_iam_role.lambda_role.arn
  handler             = "handler.lambda_handler"
  runtime             = "python3.11"
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory_size
  architectures       = ["x86_64"]

  # VPC Configuration: Run in both private subnets
  vpc_config {
    security_groups = [aws_security_group.lambda.id]
    subnet_ids      = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]
  }

  # Environment variables
  environment {
    variables = {
      MEMBERS_TABLE_NAME     = aws_dynamodb_table.members.name
      CLOUDFRONT_DOMAIN_URL  = "https://${aws_cloudfront_distribution.cdn.domain_name}"
      CORS_ORIGIN            = join(",", var.cors_allow_origins)
      LOG_LEVEL              = "INFO"
    }
  }

  # CloudWatch Logs
  # Note: Lambda automatically creates the log group with /aws/lambda prefix
  ephemeral_storage {
    size = 512 # 512 MB (maximum allowed)
  }

  # Logging
  logging_config {
    log_format = "JSON" # Structured JSON logs
    log_group  = aws_cloudwatch_log_group.lambda_logs.name
  }

  tags = {
    Name = "${local.name_prefix}-members-api"
  }

  depends_on = [
    aws_iam_role_policy.lambda_vpc_execution,
    aws_iam_role_policy.lambda_dynamodb_read,
    aws_iam_role_policy.lambda_logs,
  ]
}

# ===== CLOUDWATCH LOG GROUP FOR LAMBDA =====
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.name_prefix}-members-api"
  retention_in_days = var.lambda_log_retention_days

  tags = {
    Name = "${local.name_prefix}-lambda-logs"
  }
}

# ===== API GATEWAY HTTP API =====
# Lightweight alternative to REST API, lower cost
# See: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.name_prefix}-http-api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.members_api.arn

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key"]
    allow_methods     = ["GET", "OPTIONS"]
    allow_origins     = var.cors_allow_origins
    expose_headers    = ["Content-Length", "X-Amz-Apigw-Trace-Id"]
    max_age           = 300
  }

  tags = {
    Name = "${local.name_prefix}-http-api"
  }
}

# ===== API GATEWAY ROUTE =====
resource "aws_apigatewayv2_route" "members" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /members"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "NONE"
}

# OPTIONS route for CORS preflight
resource "aws_apigatewayv2_route" "members_options" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "OPTIONS /members"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ===== API GATEWAY INTEGRATION =====
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  payload_format_version = "2.0"
  target_resource            = aws_lambda_function.members_api.arn

  lifecycle {
    ignore_changes = [request_parameters]
  }
}

# ===== API GATEWAY STAGE =====
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = var.api_gateway_stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format          = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integration.latency"
      error          = "$context.error.message"
      errorType      = "$context.error.messageString"
    })
  }

  tags = {
    Name = "${local.name_prefix}-api-stage"
  }
}

# ===== CLOUDWATCH LOG GROUP FOR API GATEWAY =====
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${local.name_prefix}-http-api"
  retention_in_days = var.lambda_log_retention_days

  tags = {
    Name = "${local.name_prefix}-api-logs"
  }
}

# ===== Lambda Permission for API Gateway =====
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.members_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}
