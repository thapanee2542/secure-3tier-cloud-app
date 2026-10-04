variable "aws_profile" {
  # อธิบายหน้าที่ของตัวแปร aws_profile
  description = "AWS CLI profile used by the AWS provider."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ aws_profile: string
  type = string
  # ค่าเริ่มต้นของ aws_profile เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = "personal"
}

variable "aws_region" {
  # อธิบายหน้าที่ของตัวแปร aws_region
  description = "AWS region for the project resources."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ aws_region: string
  type = string
  # ค่าเริ่มต้นของ aws_region เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = "ap-southeast-7"
}

variable "project_name" {
  # อธิบายหน้าที่ของตัวแปร project_name
  description = "Project name applied to supported AWS resource tags."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ project_name: string
  type = string
  # ค่าเริ่มต้นของ project_name เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = "secure-3tier-infrastructure"
}

variable "environment" {
  # อธิบายหน้าที่ของตัวแปร environment
  description = "Environment name applied to supported AWS resource tags."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ environment: string
  type = string
  # ค่าเริ่มต้นของ environment เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = "dev"
}

variable "notification_email" {
  # อธิบายหน้าที่ของตัวแปร notification_email
  description = "Email address for future project notifications."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ notification_email: string
  type = string
}

variable "api_stage_name" {
  # อธิบายหน้าที่ของตัวแปร api_stage_name
  description = "Configured API Gateway stage name allowed to invoke the Lambda function."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ api_stage_name: string
  type = string
  # ค่าเริ่มต้นของ api_stage_name เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = "dev"
}

variable "enable_cloudwatch_logs" {
  # อธิบายหน้าที่ของตัวแปร enable_cloudwatch_logs
  description = "Whether Terraform deploys and manages the Lambda CloudWatch log group."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ enable_cloudwatch_logs: bool
  type = bool
  # ค่าเริ่มต้นของ enable_cloudwatch_logs เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = true
  # ไม่อนุญาตให้ส่ง null เพื่อให้ flag เปิดปิดมีค่าที่ชัดเจน
  nullable = false
}

variable "enable_cloudwatch_alarms" {
  # อธิบายหน้าที่ของตัวแปร enable_cloudwatch_alarms
  description = "Whether Terraform deploys both CloudWatch API alarms and their SNS/KMS notification resources."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ enable_cloudwatch_alarms: bool
  type = bool
  # ค่าเริ่มต้นของ enable_cloudwatch_alarms เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = true
  # ไม่อนุญาตให้ส่ง null เพื่อให้ flag เปิดปิดมีค่าที่ชัดเจน
  nullable = false
}