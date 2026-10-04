terraform {
  required_providers {
    # ใช้ AWS provider ของ HashiCorp
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# สร้าง IAM role ให้ Lambda ใช้เข้าถึงบริการ AWS
resource "aws_iam_role" "lambda_execution" {
  name        = "lambda-get-members-role"
  description = "Execution role assumed by the project Lambda function."

  # Trust policy: อนุญาตให้บริการ Lambda เข้ามาใช้ role นี้
  # ส่วนสิทธิ์ที่ role ทำได้จะกำหนดใน policies ด้านล่าง
  assume_role_policy = jsonencode({
    # เวอร์ชันรูปแบบ IAM policy ไม่ใช่วันที่สร้าง
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      # ให้บริการ AWS Lambda ใช้ role นี้ได้
      Principal = {
        Service = "lambda.amazonaws.com"
      }

      # AssumeRole คือการรับ credentials ชั่วคราวเพื่อทำงานด้วยสิทธิ์ของ role
      Action = "sts:AssumeRole"
    }]
  })
}

# เพิ่มสิทธิ์พื้นฐานสำหรับ Lambda ที่เชื่อมต่อ VPC
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  # ผูก policy กับ role ของ Lambda
  role = aws_iam_role.lambda_execution.name

  # ใช้ policy ที่ AWS จัดการให้
  # อนุญาตให้จัดการ network interfaces สำหรับการเชื่อมต่อ VPC
  # และสร้าง/เขียน CloudWatch logs
  # ไม่ได้ให้สิทธิ์อ่าน DynamoDB หรือกำหนดกฎ Security Group
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# เพิ่มสิทธิ์อ่านรายชื่อสมาชิกจาก DynamoDB
resource "aws_iam_role_policy" "members_table_scan" {
  # ชื่อ inline policy ที่เก็บอยู่ใน role นี้
  name = "members-table-scan"
  role = aws_iam_role.lambda_execution.name

  # แปลงกฎสิทธิ์ด้านล่างเป็น JSON ที่ IAM ใช้งาน
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      # อนุญาต Scan เพื่ออ่านข้อมูลสมาชิกในตาราง
      # กฎนี้ไม่ได้อนุญาตให้เพิ่ม แก้ไข หรือลบข้อมูล
      Action = ["dynamodb:Scan"]

      # จำกัดสิทธิ์ Scan ให้เฉพาะตารางที่ระบุ ARN นี้
      Resource = var.table_arn
    }]
  })
}