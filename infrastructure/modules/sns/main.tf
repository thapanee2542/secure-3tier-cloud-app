terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# สร้าง SNS topic สำหรับรับข้อความแจ้งเตือนจาก CloudWatch
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-${var.environment}-alarms"
}

# อนุญาตให้ CloudWatch ส่งข้อความ และปฏิเสธการเรียกผ่าน HTTP
resource "aws_sns_topic_policy" "alarms" {
  arn = aws_sns_topic.alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowProjectCloudWatchAlarmsPublish"
        Effect = "Allow"

        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }

        Action   = "sns:Publish"
        Resource = aws_sns_topic.alarms.arn

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:${var.project_name}-${var.environment}-*"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"

        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:AddPermission",
          "sns:RemovePermission",
          "sns:DeleteTopic",
          "sns:ListSubscriptionsByTopic"
        ]

        Resource = aws_sns_topic.alarms.arn

        # ปฏิเสธ HTTP สำหรับผู้เรียกที่ไม่ใช่ AWS service โดยตรง
        Condition = {
          Bool = {
            "aws:SecureTransport"       = "false"
            "aws:PrincipalIsAWSService" = "false"
          }
        }
      }
    ]
  })
}

# สมัครรับข้อความแจ้งเตือนผ่านอีเมล
resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.notification_email
}