terraform {
  required_providers {
    # ใช้ AWS provider ของ HashiCorp
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_dynamodb_table" "members" {
  # ชื่อตารางที่แสดงใน AWS
  name = "members-data-table"

  # กำหนดความสามารถในการอ่านและเขียนเอง
  billing_mode = "PROVISIONED"

  # อ่านได้ 1 RCU: ประมาณ 1 strongly consistent read/วินาที
  # หรือ 2 eventually consistent reads/วินาที สำหรับ item ขนาดไม่เกิน 4 KB
  read_capacity = 1

  # เขียนได้ 1 WCU: ประมาณ 1 write/วินาที สำหรับ item ขนาดไม่เกิน 1 KB
  write_capacity = 1

  # ใช้ memberId เป็นคีย์ระบุสมาชิก โดยแต่ละคนต้องมีค่าไม่ซ้ำกัน
  hash_key = "memberId"

  # ใช้ตารางประเภท STANDARD สำหรับการใช้งานทั่วไป
  table_class = "STANDARD"

  # ประกาศชนิดข้อมูลของคีย์ ไม่ต้องประกาศทุก field ที่เก็บในตาราง
  attribute {
    name = "memberId"
    type = "S" # S = String
  }

  # เข้ารหัสข้อมูลที่จัดเก็บด้วย AWS managed KMS key
  # เนื่องจากไม่ได้ระบุ kms_key_arn
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    # สำรองข้อมูลอย่างต่อเนื่อง เพื่อกู้คืนก่อนแก้ไขหรือลบข้อมูลผิดพลาด
    enabled = true

    # เลือกเวลากู้คืนย้อนหลังได้ภายใน 1 วันล่าสุด
    # การกู้คืนจะสร้างตารางใหม่ ไม่เขียนทับตารางเดิม
    recovery_period_in_days = 1
  }
}

resource "aws_dynamodb_table_item" "demo_member" {
  # สร้างข้อมูลสมาชิก 1 รายการต่อ 1 entry ใน var.members
  # โดยใช้ key ของแต่ละ entry เป็นตัวอ้างอิง resource ใน Terraform
  for_each = var.members

  # บันทึกข้อมูลลงตารางสมาชิกที่สร้างไว้ด้านบน
  table_name = aws_dynamodb_table.members.name

  # ระบุว่าตารางนี้ใช้ field ใดเป็น partition key
  hash_key = aws_dynamodb_table.members.hash_key

  # แปลงข้อมูลเป็น JSON ตามรูปแบบ DynamoDB โดย S หมายถึง String
  item = jsonencode({
    # ใช้ key ใน var.members เป็น memberId เช่น "1", "2", "3"
    memberId = { S = each.key }

    # เก็บรหัสนักศึกษาเป็น String เพื่อรักษาเลขศูนย์นำหน้า
    studentId = { S = each.value.studentId }

    # ชื่อสมาชิก
    name = { S = each.value.name }

    # บทบาทในทีม เช่น Developer
    role = { S = each.value.role }
  })
}