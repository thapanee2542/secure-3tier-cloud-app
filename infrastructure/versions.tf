terraform {
  # กำหนดช่วงเวอร์ชัน Terraform CLI ที่ configuration นี้รองรับ
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    # ประกาศ dependency ของ AWS provider ซึ่งรับการตั้งค่าจาก root module
    aws = {
      # ระบุแหล่ง provider ใน Terraform Registry โดยไม่ได้สร้าง provider configuration ใหม่
      source = "hashicorp/aws"
      # กำหนดช่วงเวอร์ชัน provider ที่ติดตั้งได้ โดย lockfile เก็บเวอร์ชันที่เลือกจริง
      version = "~> 5.0"
    }
    # ประกาศ dependency ของ archive provider สำหรับสร้างไฟล์ ZIP
    archive = {
      # ระบุแหล่ง provider ใน Terraform Registry โดยไม่ได้สร้าง provider configuration ใหม่
      source = "hashicorp/archive"
      # กำหนดช่วงเวอร์ชัน provider ที่ติดตั้งได้ โดย lockfile เก็บเวอร์ชันที่เลือกจริง
      version = "~> 2.7"
    }
  }
}