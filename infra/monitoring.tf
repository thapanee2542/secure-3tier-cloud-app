/**
 * MONITORING - CloudWatch Dashboards and Metrics
 * 
 * Cost-conscious monitoring:
 * - Core logs are free (CloudWatch Logs are included in service)
 * - Alarms: $0.10 per alarm per month
 * - Custom metrics: $0.30 per metric per month
 * - Dashboard: Free
 * 
 * This setup uses only free/minimal cost monitoring
 */

# ===== CLOUDWATCH DASHBOARD =====
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Duration", { stat = "Average", label = "Duration (ms)" }],
            [".", "ConcurrentExecutions", { stat = "Maximum", label = "Concurrent" }],
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum" }],
            [".", "UserErrors", { stat = "Sum" }],
            ["AWS/CloudFront", "Requests", { stat = "Sum" }],
            [".", "BytesDownloaded", { stat = "Sum" }],
            [".", "4xxErrorRate", { stat = "Average" }],
            [".", "5xxErrorRate", { stat = "Average" }],
          ]
          period = 300
          stat   = "Average"
          region = local.aws_region
          title  = "Secure 3-Tier App - Overview"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message, @logStream | filter @message like /ERROR/ | stats count() by @logStream"
          region  = local.aws_region
          title   = "Recent Errors"
        }
      }
    ]
  })
}

# ===== LAMBDA METRICS =====
# Lambda metrics are automatically collected

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.name_prefix}-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when Lambda errors exceed threshold"
  alarm_actions       = []
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.members_api.function_name
  }

  tags = {
    Name = "${local.name_prefix}-lambda-errors"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${local.name_prefix}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 20000  # 20 seconds
  alarm_description   = "Alert when Lambda duration is unexpectedly high"
  alarm_actions       = []
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.members_api.function_name
  }

  tags = {
    Name = "${local.name_prefix}-lambda-duration"
  }
}

# ===== CloudFront METRICS =====
# CloudFront metrics are automatically collected

resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  alarm_name          = "${local.name_prefix}-cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "Alert when CloudFront 4xx error rate exceeds 5%"
  alarm_actions       = []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.cdn.id
  }

  tags = {
    Name = "${local.name_prefix}-cloudfront-4xx"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  alarm_name          = "${local.name_prefix}-cloudfront-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when CloudFront 5xx error rate exceeds 1%"
  alarm_actions       = []
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.cdn.id
  }

  tags = {
    Name = "${local.name_prefix}-cloudfront-5xx"
  }
}

# ===== Log Insights Queries for Debugging =====
# These can be run manually in CloudWatch Logs Insights

# Query 1: Lambda errors with stack traces
# fields @timestamp, @message, @logStream
# | filter @message like /ERROR/ or @message like /Exception/
# | stats count() by @logStream

# Query 2: API Gateway latency
# fields @timestamp, @duration, @status, @memUsed
# | stats avg(@duration), max(@duration), pct(@duration, 99) by bin(5m)

# Query 3: DynamoDB throttling
# fields @timestamp, @message
# | filter @message like /ProvisionedThroughputExceededException/

# TODO(CLOUD): Add SNS topic for alarm notifications
# resource "aws_sns_topic" "alerts" {
#   name = "${local.name_prefix}-alerts"
# }
#
# resource "aws_sns_topic_subscription" "alerts_email" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = "your-email@example.com"
# }
