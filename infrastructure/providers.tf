provider "aws" {
  # เลือก AWS CLI profile ที่ใช้ credentials เพื่อ deploy
  profile = var.aws_profile
  # เลือก AWS region ที่ provider จะสร้างและจัดการ resource
  region = var.aws_region

  default_tags {
    # กำหนด metadata tags เพื่อระบุเจ้าของและกลุ่มของ resource ที่รองรับ tags
    tags = {
      # ติด tag ชื่อโปรเจกต์ให้ resource
      Project = var.project_name
      # ติด tag environment เช่น dev หรือ prod ให้ resource
      Environment = var.environment
      # ระบุว่า resource ถูกจัดการด้วย Terraform
      ManagedBy = "Terraform"
    }
  }
}