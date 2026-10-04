variable "project_name" {
  # อธิบายหน้าที่ของตัวแปร project_name
  description = "Project prefix for the origin access control name."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ project_name: string
  type = string
}

variable "environment" {
  # อธิบายหน้าที่ของตัวแปร environment
  description = "Environment prefix for the origin access control name."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ environment: string
  type = string
}

variable "bucket_regional_domain_name" {
  # อธิบายหน้าที่ของตัวแปร bucket_regional_domain_name
  description = "Regional domain name of the private frontend bucket."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ bucket_regional_domain_name: string
  type = string
}

variable "api_domain_name" {
  # อธิบายหน้าที่ของตัวแปร api_domain_name
  description = "Regional API Gateway domain for the members origin."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ api_domain_name: string
  type = string
}

variable "api_stage_name" {
  # อธิบายหน้าที่ของตัวแปร api_stage_name
  description = "Stage path prepended to member requests."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ api_stage_name: string
  type = string
}