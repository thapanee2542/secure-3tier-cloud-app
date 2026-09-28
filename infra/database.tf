/**
 * DATABASE - DynamoDB Table for Members
 * 
 * Design:
 * - Table Name: Members
 * - Primary Key: id (string)
 * - Attributes: name, role, bio, photoKey
 * - Billing: PAY_PER_REQUEST (optimal for low traffic)
 * - Encryption: Enabled
 * - Backup: Enabled with PITR (Point-in-Time Recovery)
 * 
 * Cost Considerations:
 * - PAY_PER_REQUEST: ~$1.25 per GB written, ~$0.25 per GB read
 * - Free tier: 25 RCU and 25 WCU for provisioned tables
 * - No free tier for on-demand billing, but low cost for small data
 * - PITR: $0.20 per GB per month (incremental backup)
 * 
 * For classroom project, costs will be minimal
 */

# ===== DYNAMODB TABLE =====
resource "aws_dynamodb_table" "members" {
  name           = "${local.name_prefix}-members"
  billing_mode   = var.members_table_billing_mode
  hash_key       = "id"

  # Attributes
  attribute {
    name = "id"
    type = "S"
  }

  # Enable encryption with AWS managed keys
  server_side_encryption_specification {
    enabled = true
  }

  # Enable PITR for disaster recovery
  point_in_time_recovery_specification {
    point_in_time_recovery_enabled = true
  }

  # TTL not needed for this table
  # ttl {
  #   attribute_name = "expirationTime"
  #   enabled        = true
  # }

  # Optional: DynamoDB Streams for change data capture
  stream_specification {
    stream_view_type = var.members_table_stream_specification ? "NEW_AND_OLD_IMAGES" : null
  }

  # Tags
  tags = {
    Name = "${local.name_prefix}-members-table"
    Tier = "Data"
  }
}

# ===== CLOUDWATCH ALARMS FOR DYNAMODB =====
# Monitor for throttling and errors

# Throttled write requests
resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  alarm_name          = "${local.name_prefix}-dynamodb-write-throttle"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when DynamoDB write throttling occurs"
  alarm_actions       = [] # TODO(CLOUD): Add SNS topic for notifications
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.members.name
  }

  tags = {
    Name = "${local.name_prefix}-dynamodb-write-throttle"
  }
}

# Throttled read requests
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  alarm_name          = "${local.name_prefix}-dynamodb-read-throttle"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when DynamoDB read throttling occurs"
  alarm_actions       = []
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.members.name
  }

  tags = {
    Name = "${local.name_prefix}-dynamodb-read-throttle"
  }
}

# ===== MEMBER DATA SEEDING HELPER =====
# After Terraform apply, use the AWS CLI to seed the table:
#
# Example: aws dynamodb put-item \
#   --table-name secure-3tier-app-dev-members \
#   --item '{
#     "id": {"S": "member-001"},
#     "name": {"S": "Alice Johnson"},
#     "role": {"S": "Project Lead & Full-Stack Engineer"},
#     "bio": {"S": "Leader in cloud security..."},
#     "photoKey": {"S": "photos/alice-johnson.jpg"}
#   }' \
#   --region us-east-1
#
# OR use the provided seeding script:
#   python scripts/seed-dynamodb.py --table-name <TABLE_NAME> --region <REGION>
