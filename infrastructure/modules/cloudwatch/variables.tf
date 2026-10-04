variable "project_name" {
  # อธิบายหน้าที่ของตัวแปร project_name
  description = "Project prefix for alarm names."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ project_name: string
  type = string
}

variable "environment" {
  # อธิบายหน้าที่ของตัวแปร environment
  description = "Environment prefix for alarm names."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ environment: string
  type = string
}

variable "api_name" {
  # อธิบายหน้าที่ของตัวแปร api_name
  description = "API Gateway name used in alarm dimensions."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ api_name: string
  type = string
}

variable "api_stage_name" {
  # อธิบายหน้าที่ของตัวแปร api_stage_name
  description = "Deployed API stage used in alarm dimensions."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ api_stage_name: string
  type = string
}

variable "alarm_topic_arn" {
  # อธิบายหน้าที่ของตัวแปร alarm_topic_arn
  description = "SNS topic receiving alarm notifications."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ alarm_topic_arn: string
  type = string
}

variable "enable_log_group" {
  # อธิบายหน้าที่ของตัวแปร enable_log_group
  description = "Whether Terraform deploys and manages the Lambda log group."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ enable_log_group: bool
  type = bool
  # ค่าเริ่มต้นของ enable_log_group เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = true
  # ไม่อนุญาตให้ส่ง null เพื่อให้ flag เปิดปิดมีค่าที่ชัดเจน
  nullable = false
}

variable "enable_metric_alarms" {
  # อธิบายหน้าที่ของตัวแปร enable_metric_alarms
  description = "Whether Terraform deploys both API metric alarms."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ enable_metric_alarms: bool
  type = bool
  # ค่าเริ่มต้นของ enable_metric_alarms เมื่อไม่ได้ส่งค่าจากผู้เรียก
  default = true
  # ไม่อนุญาตให้ส่ง null เพื่อให้ flag เปิดปิดมีค่าที่ชัดเจน
  nullable = false
}