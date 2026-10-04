variable "project_name" {
  # อธิบายหน้าที่ของตัวแปร project_name
  description = "Project prefix for the unique frontend bucket name."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ project_name: string
  type = string
}

variable "environment" {
  # อธิบายหน้าที่ของตัวแปร environment
  description = "Environment prefix for the frontend bucket name."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ environment: string
  type = string
}

variable "account_id" {
  # อธิบายหน้าที่ของตัวแปร account_id
  description = "AWS account ID used to make the bucket name unique."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ account_id: string
  type = string
}

variable "aws_region" {
  # อธิบายหน้าที่ของตัวแปร aws_region
  description = "AWS region included in the bucket name."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ aws_region: string
  type = string
}

variable "cloudfront_distribution_arn" {
  # อธิบายหน้าที่ของตัวแปร cloudfront_distribution_arn
  description = "Only distribution allowed to read objects through OAC."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ cloudfront_distribution_arn: string
  type = string
}

variable "image_directory" {
  # อธิบายหน้าที่ของตัวแปร image_directory
  description = "Root-relative directory containing static member images."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ image_directory: string
  type = string
}

variable "member_image_files" {
  # อธิบายหน้าที่ของตัวแปร member_image_files
  description = "Image filenames used as stable S3 resource keys."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ member_image_files: map(string)
  type = map(string)
}

variable "frontend_directory" {
  # อธิบายหน้าที่ของตัวแปร frontend_directory
  description = "Root-relative directory containing the generated frontend build."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ frontend_directory: string
  type = string
}

variable "frontend_files" {
  # อธิบายหน้าที่ของตัวแปร frontend_files
  description = "Frontend filenames used as stable S3 resource keys."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ frontend_files: set(string)
  type = set(string)
}

variable "frontend_content_types" {
  # อธิบายหน้าที่ของตัวแปร frontend_content_types
  description = "Content types keyed by frontend filename extension."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ frontend_content_types: map(string)
  type = map(string)
}