terraform {
  required_providers {
    # ใช้ AWS provider ของ HashiCorp
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# สร้าง S3 bucket สำหรับเก็บไฟล์หน้าเว็บและรูปสมาชิก
resource "aws_s3_bucket" "frontend" {
  # รวมชื่อโปรเจกต์ environment account และ region เพื่อลดโอกาสชื่อซ้ำ
  # ชื่อ S3 bucket ต้องไม่ซ้ำกับ bucket ของผู้อื่นใน AWS partition เดียวกัน
  bucket = "${var.project_name}-${var.environment}-${var.account_id}-${var.aws_region}"

  # ไม่ลบไฟล์ทั้งหมดให้อัตโนมัติเมื่อ destroy bucket
  # แต่ไฟล์ที่ Terraform จัดการผ่าน aws_s3_object ยังถูกลบเมื่อ destroy ได้
  force_destroy = false
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    # ให้เจ้าของ bucket เป็นเจ้าของไฟล์ทุกไฟล์ และปิด ACL
    # ใช้ IAM policy และ bucket policy ควบคุมสิทธิ์แทน
    object_ownership = "BucketOwnerEnforced"
  }
}

# ป้องกันการเปิด bucket หรือไฟล์ให้เข้าถึงแบบ public โดยตรง
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  # ปฏิเสธการตั้ง ACL ใหม่ที่ให้สิทธิ์ public
  block_public_acls = true

  # ปฏิเสธการตั้ง bucket policy ใหม่ที่ให้สิทธิ์ public
  block_public_policy = true

  # ไม่ใช้สิทธิ์ public ที่มีอยู่ใน ACL
  ignore_public_acls = true

  # หาก bucket มี public policy ให้จำกัดการเข้าถึง
  # เหลือเฉพาะ AWS services และผู้มีสิทธิ์ในบัญชีเจ้าของ bucket
  restrict_public_buckets = true
}

# กำหนดการเข้ารหัสไฟล์ที่จัดเก็บใน S3 เป็นค่าเริ่มต้น
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      # ใช้ SSE-S3: เข้ารหัสด้วย AES-256 โดย S3 จัดการกุญแจให้
      sse_algorithm = "AES256"
    }
  }
}

# อัปโหลดรูปสมาชิกจากเครื่องที่รัน Terraform ไป S3
resource "aws_s3_object" "member_images" {
  # สร้าง 1 resource ต่อ 1 รูป โดยใช้ key ใน map เป็นตัวอ้างอิง resource
  for_each = var.member_image_files

  bucket = aws_s3_bucket.frontend.id

  # เก็บรูปไว้ใต้ images/ เช่น images/6907031857211.jpg
  key = "images/${each.value}"

  # ตำแหน่งไฟล์รูปในเครื่องที่รัน Terraform
  source = "${var.image_directory}/${each.value}"

  # ระบุว่าไฟล์เป็น JPEG เพื่อให้ browser แสดงรูปได้ถูกต้อง
  content_type = "image/jpeg"

  # ให้ browser และ shared cache เก็บรูปได้ 1 ชั่วโมง
  # คำว่า public ใน header นี้ไม่ได้เปิดสิทธิ์ public access ของ S3
  cache_control = "public,max-age=3600"

  # ตรวจการเปลี่ยนเนื้อหารูปด้วย MD5 เพื่ออัปโหลดรูปใหม่เมื่อไฟล์เปลี่ยน
  etag = filemd5("${var.image_directory}/${each.value}")
}

# อัปโหลดไฟล์เว็บที่ build แล้ว เช่น index.html, JavaScript และ CSS
resource "aws_s3_object" "frontend_files" {
  # สร้าง 1 resource ต่อ 1 ไฟล์ในชุด frontend build
  for_each = var.frontend_files

  bucket = aws_s3_bucket.frontend.id

  # ใช้ path เดิมจาก build เช่น index.html หรือ assets/app-abc123.js
  key = each.value

  # ตำแหน่งไฟล์ build ในเครื่องที่รัน Terraform
  source = "${var.frontend_directory}/${each.value}"

  # ตรวจการเปลี่ยนเนื้อหาไฟล์เพื่ออัปโหลดใหม่ โดยไม่พึ่ง ETag ของ S3
  source_hash = filemd5("${var.frontend_directory}/${each.value}")

  # เลือก Content-Type ตามนามสกุลไฟล์จาก map ที่กำหนด
  # หากไม่พบ ให้ใช้ application/octet-stream ซึ่งเป็นข้อมูล binary ทั่วไป
  content_type = lookup(
    var.frontend_content_types,
    lower(element(reverse(split(".", each.value)), 0)),
    "application/octet-stream",
  )

  # index.html: ไม่ให้เก็บ cache เพื่อให้โหลดหน้าเว็บเวอร์ชันล่าสุด
  # ไฟล์อื่น: ให้ cache 1 ปี และระบุว่าเนื้อหาไม่เปลี่ยนระหว่างอายุ cache
  # จึงควรใช้ชื่อไฟล์ที่เปลี่ยนตามเนื้อหา เช่นชื่อที่มี hash จาก build
  # อายุ cache ที่ CloudFront ใช้จริงยังถูกจำกัดด้วย max_ttl ของ behavior
  cache_control = each.value == "index.html" ? "no-cache, no-store, must-revalidate" : "public,max-age=31536000,immutable"
}

# อนุญาตให้ CloudFront อ่านไฟล์ และปฏิเสธ HTTP สำหรับผู้เรียกทั่วไป
resource "aws_s3_bucket_policy" "frontend_cloudfront" {
  bucket = aws_s3_bucket.frontend.id

  # แปลงกฎสิทธิ์ด้านล่างเป็น JSON ที่ S3 ใช้งาน
  policy = jsonencode({
    # เวอร์ชันรูปแบบ IAM policy ไม่ใช่วันที่สร้าง
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowCloudFrontReadOnly"
        Effect = "Allow"

        # ให้บริการ CloudFront อ่านไฟล์จาก bucket ผ่าน OAC
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        # อนุญาตให้อ่านไฟล์เท่านั้น ไม่ให้เพิ่ม แก้ไข หรือลบ
        Action = "s3:GetObject"

        # อนุญาตให้อ่านไฟล์ทุก path ใน bucket นี้
        Resource = "${aws_s3_bucket.frontend.arn}/*"

        Condition = {
          StringEquals = {
            # ให้สิทธิ์เฉพาะ CloudFront distribution ที่ระบุ ARN นี้
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      },
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"

        # ใช้กฎปฏิเสธนี้กับผู้เรียกทุกคนที่ตรงเงื่อนไขด้านล่าง
        Principal = "*"
        Action    = "s3:*"

        # ครอบคลุมทั้งการทำงานกับ bucket และไฟล์ภายใน
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*",
        ]

        Condition = {
          # ปฏิเสธเมื่อทั้งสองเงื่อนไขเป็นจริง:
          # ใช้ HTTP และผู้เรียกไม่ใช่ AWS service โดยตรง
          Bool = {
            "aws:SecureTransport"       = "false"
            "aws:PrincipalIsAWSService" = "false"
          }
        }
      }
    ]
  })
}