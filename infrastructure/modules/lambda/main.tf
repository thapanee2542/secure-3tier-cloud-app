terraform {
  required_providers {
    # ใช้ AWS provider เพื่อสร้าง Lambda
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }

    # ใช้ archive provider เพื่อรวมไฟล์โค้ดเป็น ZIP
    archive = {
      source = "hashicorp/archive"
    }
  }
}

# เตรียมไฟล์ ZIP ของโค้ดก่อนอัปโหลดไป Lambda
data "archive_file" "get_members" {
  type = "zip"

  # นำไฟล์ Python ที่กำหนดเพียงไฟล์เดียวใส่ใน ZIP
  # ไม่รวมไฟล์อื่นหรือ libraries ที่ติดตั้งไว้ในเครื่อง
  source_file = var.source_file

  # ตำแหน่งที่บันทึกไฟล์ ZIP ในเครื่องที่รัน Terraform
  output_path = var.archive_path
}

# สร้าง Lambda สำหรับอ่านข้อมูลสมาชิกและส่ง response กลับให้ API Gateway
resource "aws_lambda_function" "get_members" {
  # ชื่อ function ที่แสดงใน AWS Lambda
  function_name = var.function_name

  # ให้ Lambda ใช้สิทธิ์จาก IAM role นี้
  # เช่น อ่าน DynamoDB, เขียน logs และจัดการ network interfaces สำหรับ VPC
  role = var.execution_role_arn

  # รันโค้ดด้วย Python 3.13
  runtime = "python3.13"

  # เริ่มทำงานที่ฟังก์ชัน lambda_handler ในไฟล์ get_members.py
  handler = "get_members.lambda_handler"

  # อัปโหลดโค้ดจากไฟล์ ZIP ที่เตรียมไว้ด้านบน
  filename = data.archive_file.get_members.output_path

  # เมื่อเนื้อหา ZIP เปลี่ยน hash จะเปลี่ยน
  # ทำให้ Terraform อัปเดตโค้ดของ Lambda
  source_code_hash = data.archive_file.get_members.output_base64sha256

  # จัดสรรหน่วยความจำ 128 MB
  # ขนาดหน่วยความจำมีผลต่อ CPU ที่ได้รับและค่าใช้จ่าย
  memory_size = 128

  # หยุดการทำงานหาก function รันเกิน 30 วินาที
  timeout = 30

  environment {
    # ส่งค่าตั้งต้นให้โค้ด Python อ่านผ่าน environment variables
    variables = {
      # ชื่อตาราง DynamoDB ที่ใช้เก็บข้อมูลสมาชิก
      TABLE_NAME = var.table_name

      # URL ตั้งต้นของรูปภาพ เช่น https://dxxxx.cloudfront.net
      # handler นำไปประกอบเป็น URL รูปของสมาชิก
      IMAGE_BASE_URL = var.image_base_url
    }
  }

  # เชื่อม Lambda เข้ากับ VPC เพื่อใช้เส้นทางเครือข่ายที่กำหนด
  vpc_config {
    # เลือก subnets สำหรับเชื่อมต่อ VPC
    # ต้องส่ง IDs ของ private subnets เข้ามาหากต้องการใช้ private subnets
    subnet_ids = var.subnet_ids

    # ใช้ Security Group นี้ควบคุม traffic ผ่านการเชื่อมต่อ VPC ของ Lambda
    security_group_ids = [var.security_group_id]
  }

  tracing_config {
    # ไม่เปิด Active tracing ของ Lambda
    # แต่ส่งต่อ tracing context ที่ได้รับจากบริการต้นทาง
    mode = "PassThrough"
  }
}