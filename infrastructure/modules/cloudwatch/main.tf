terraform {
  required_providers {
    # ใช้ AWS provider ของ HashiCorp
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# สร้างพื้นที่เก็บ logs ของ Lambda
# Lambda ต้องมีสิทธิ์เขียน logs และใช้ชื่อ function ตรงกับ log group นี้
resource "aws_cloudwatch_log_group" "lambda" {
  # true = สร้าง log group, false = ไม่สร้าง
  # หากเคยสร้างไว้แล้วเปลี่ยนเป็น false Terraform จะลบ log group นี้
  count = var.enable_log_group ? 1 : 0

  # ชื่อ log group สำหรับ Lambda function ชื่อ get-members
  name = "/aws/lambda/get-members"

  # เก็บแต่ละ log event ไว้ 3 วัน แล้วลบอัตโนมัติ
  retention_in_days = 3
}

# แจ้งเตือนเมื่อ API ได้รับ requests มากผิดปกติ
resource "aws_cloudwatch_metric_alarm" "api_request_count" {
  # true = สร้าง alarm, false = ไม่สร้าง
  # หากเคยสร้างไว้แล้วเปลี่ยนเป็น false Terraform จะลบ alarm นี้
  count = var.enable_metric_alarms ? 1 : 0

  # ตั้งชื่อ alarm ตามโปรเจกต์ environment และเหตุการณ์ที่ตรวจจับ
  alarm_name        = "${var.project_name}-${var.environment}-api-request-count"
  alarm_description = "API Gateway received more than 300 requests in five minutes."

  # ตรวจจำนวน requests ของ API Gateway
  namespace   = "AWS/ApiGateway"
  metric_name = "Count"

  # รวมจำนวน requests ในแต่ละช่วง 5 นาที (300 วินาที)
  period    = 300
  statistic = "Sum"

  # แจ้งเตือนเมื่อมีมากกว่า 300 requests ในช่วงที่ประเมิน
  # หากเท่ากับ 300 ยังไม่ถือว่าเกิน
  comparison_operator = "GreaterThanThreshold"
  threshold           = 300

  # ใช้ข้อมูล 1 ช่วงเวลา และให้ alarm เมื่อช่วงนั้นเกิน threshold
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  # หากไม่มีข้อมูลในช่วงนั้น ให้ถือว่าไม่เกิน threshold
  treat_missing_data = "notBreaching"

  # ตรวจเฉพาะ API และ stage ที่กำหนด
  dimensions = {
    ApiName = var.api_name
    Stage   = var.api_stage_name
  }

  # ส่งแจ้งเตือนไป SNS เมื่อ alarm เปลี่ยนเข้าสถานะ ALARM
  # การส่งต่อเป็น email ต้องมี subscription ที่ยืนยันแล้วใน SNS
  alarm_actions = [var.alarm_topic_arn]
}

# แจ้งเตือนเมื่อ API ตอบกลับด้วย HTTP 4xx จำนวนมากผิดปกติ
resource "aws_cloudwatch_metric_alarm" "api_client_errors" {
  # true = สร้าง alarm, false = ไม่สร้าง
  # หากเคยสร้างไว้แล้วเปลี่ยนเป็น false Terraform จะลบ alarm นี้
  count = var.enable_metric_alarms ? 1 : 0

  # ตั้งชื่อ alarm ตามโปรเจกต์ environment และเหตุการณ์ที่ตรวจจับ
  alarm_name        = "${var.project_name}-${var.environment}-api-client-errors"
  alarm_description = "API Gateway returned more than 30 client errors in five minutes."

  # ตรวจจำนวน HTTP 4xx ของ API Gateway เช่น 403, 404 และ 429
  namespace   = "AWS/ApiGateway"
  metric_name = "4XXError"

  # รวมจำนวน errors ในแต่ละช่วง 5 นาที (300 วินาที)
  period    = 300
  statistic = "Sum"

  # แจ้งเตือนเมื่อมีมากกว่า 30 errors ในช่วงที่ประเมิน
  # หากเท่ากับ 30 ยังไม่ถือว่าเกิน
  comparison_operator = "GreaterThanThreshold"
  threshold           = 30

  # ใช้ข้อมูล 1 ช่วงเวลา และให้ alarm เมื่อช่วงนั้นเกิน threshold
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  # หากไม่มีข้อมูลในช่วงนั้น ให้ถือว่าไม่เกิน threshold
  treat_missing_data = "notBreaching"

  # ตรวจเฉพาะ API และ stage ที่กำหนด
  dimensions = {
    ApiName = var.api_name
    Stage   = var.api_stage_name
  }

  # ส่งแจ้งเตือนไป SNS เมื่อ alarm เปลี่ยนเข้าสถานะ ALARM
  alarm_actions = [var.alarm_topic_arn]
}