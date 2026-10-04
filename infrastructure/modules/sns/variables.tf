variable "project_name" {
  # อธิบายหน้าที่ของตัวแปร project_name
  description = "Project prefix for the topic and permitted alarms."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ project_name: string
  type = string
}

variable "environment" {
  # อธิบายหน้าที่ของตัวแปร environment
  description = "Environment prefix for the topic and permitted alarms."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ environment: string
  type = string
}

variable "aws_region" {
  # อธิบายหน้าที่ของตัวแปร aws_region
  description = "Region of the CloudWatch alarms permitted to publish."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ aws_region: string
  type = string
}

variable "account_id" {
  # อธิบายหน้าที่ของตัวแปร account_id
  description = "Only AWS account allowed in the CloudWatch publishing policy."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ account_id: string
  type = string
}

variable "notification_email" {
  # อธิบายหน้าที่ของตัวแปร notification_email
  description = "Email address for the alarm subscription."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ notification_email: string
  type = string
}