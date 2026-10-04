variable "project_name" {
  # อธิบายหน้าที่ของตัวแปร project_name
  description = "Project prefix for the Lambda security group."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ project_name: string
  type = string
}

variable "environment" {
  # อธิบายหน้าที่ของตัวแปร environment
  description = "Environment prefix for the Lambda security group."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ environment: string
  type = string
}

variable "aws_region" {
  # อธิบายหน้าที่ของตัวแปร aws_region
  description = "Region for the DynamoDB Gateway endpoint."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ aws_region: string
  type = string
}

variable "table_arn" {
  # อธิบายหน้าที่ของตัวแปร table_arn
  description = "Only DynamoDB table allowed by the endpoint policy."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ table_arn: string
  type = string
}

variable "execution_role_arn" {
  # อธิบายหน้าที่ของตัวแปร execution_role_arn
  description = "Lambda role permitted to access DynamoDB through the endpoint."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ execution_role_arn: string
  type = string
}