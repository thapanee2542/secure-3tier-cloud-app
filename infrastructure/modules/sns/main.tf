terraform {
  required_providers {
    # ใช้ AWS provider ของ HashiCorp
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# สร้าง KMS key สำหรับเข้ารหัสข้อความแจ้งเตือนที่เก็บใน SNS
resource "aws_kms_key" "alarms" {
  description = "Encrypt SNS alarm notifications for ${var.project_name}-${var.environment}."

  # เปลี่ยนวัสดุกุญแจเข้ารหัสอัตโนมัติ
  # โดยยังใช้ key เดิมและถอดรหัสข้อมูลเก่าได้
  enable_key_rotation = true

  # เมื่อสั่งลบ key ให้รอ 7 วันก่อนลบจริง
  # ระหว่างรอลบ key จะใช้งานไม่ได้ แต่ยังยกเลิกการลบได้
  deletion_window_in_days = 7

  # กำหนดว่าใครสามารถจัดการหรือใช้ key นี้ได้
  policy = jsonencode({
    # เวอร์ชันรูปแบบ IAM policy ไม่ใช่วันที่สร้าง
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableAccountKeyAdministration"
        Effect = "Allow"

        # ให้บัญชีเจ้าของ key สามารถมอบสิทธิ์ผ่าน IAM policies ได้
        # ไม่ได้หมายความว่าผู้ใช้ทุกคนในบัญชีมีสิทธิ์ทันที
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }

        # เปิดให้ IAM policies ของบัญชีมอบสิทธิ์จัดการและใช้ key นี้
        Action = "kms:*"

        # ใน key policy ค่า * หมายถึง KMS key ที่ policy นี้ผูกอยู่
        Resource = "*"
      },
      {
        Sid    = "AllowProjectCloudWatchAlarmEncryption"
        Effect = "Allow"

        # ให้ CloudWatch ใช้ key เมื่อส่ง alarm ไปยัง SNS ที่เข้ารหัส
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }

        # อนุญาตให้สร้าง data key และถอดรหัสตามที่การส่งข้อความต้องใช้
        Action   = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource = "*"

        # ให้สิทธิ์เฉพาะคำขอจาก alarms ของโปรเจกต์นี้
        Condition = {
          StringEquals = {
            # Alarm ต้นทางต้องอยู่ในบัญชีที่กำหนด
            "aws:SourceAccount" = var.account_id
          }
          ArnLike = {
            # Alarm ต้องอยู่ใน region นี้ และชื่อขึ้นต้นด้วย project-environment-
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:${var.project_name}-${var.environment}-*"
          }
        }
      }
    ]
  })
}

# ตั้งชื่อที่อ่านง่ายสำหรับอ้างอิง KMS key
resource "aws_kms_alias" "alarms" {
  name = "alias/${var.project_name}-${var.environment}-sns-alarms"

  # ให้ alias นี้ชี้ไปยัง key สำหรับข้อความแจ้งเตือน
  target_key_id = aws_kms_key.alarms.key_id
}

# สร้างช่องทางรับข้อความจาก CloudWatch แล้วส่งต่อให้ผู้ติดตาม
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-${var.environment}-alarms"

  # เข้ารหัสข้อความที่เก็บใน SNS ด้วย KMS key นี้
  # ไม่ใช่การเข้ารหัสแบบ end-to-end ไปถึงกล่องอีเมล
  kms_master_key_id = aws_kms_key.alarms.arn
}

# กำหนดสิทธิ์ส่งข้อความเข้า SNS topic และปฏิเสธการเรียกผ่าน HTTP
resource "aws_sns_topic_policy" "alarms" {
  arn = aws_sns_topic.alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowProjectCloudWatchAlarmsPublish"
        Effect = "Allow"

        # ให้บริการ CloudWatch ส่งข้อความแจ้งเตือนได้
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }

        # อนุญาตให้ส่งข้อความเข้า topic นี้เท่านั้น
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alarms.arn

        Condition = {
          StringEquals = {
            # Alarm ต้นทางต้องอยู่ในบัญชีที่กำหนด
            "aws:SourceAccount" = var.account_id
          }
          ArnLike = {
            # Alarm ต้องอยู่ใน region นี้ และชื่อขึ้นต้นด้วย project-environment-
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:${var.project_name}-${var.environment}-*"
          }
        }
      },
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"

        # ใช้กฎปฏิเสธนี้กับผู้เรียกทุกคนที่ตรงเงื่อนไขด้านล่าง
        Principal = "*"
        Action    = "sns:*"
        Resource  = aws_sns_topic.alarms.arn

        Condition = {
          # ปฏิเสธเมื่อทั้งสองเงื่อนไขเป็นจริง:
          # ใช้ HTTP และผู้เรียกไม่ใช่ AWS service โดยตรง
          Bool = {
            "aws:SecureTransport"       = "false"
            "aws:PrincipalIsAWSService" = "false"
          }
        }
      }
    ]
  })
}

# สมัครรับข้อความแจ้งเตือนจาก SNS ผ่านอีเมล
resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"

  # SNS จะส่งอีเมลยืนยันไปยังที่อยู่นี้
  # ผู้รับต้องกด Confirm subscription ก่อนจึงจะรับข้อความแจ้งเตือนได้
  endpoint = var.notification_email
}