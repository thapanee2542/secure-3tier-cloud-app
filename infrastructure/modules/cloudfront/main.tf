terraform {
  required_providers {
    # ใช้ AWS provider ของ HashiCorp
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# สร้าง OAC เพื่อให้ CloudFront ยืนยันตัวตนเมื่ออ่านไฟล์จาก S3
# ต้องมี S3 bucket policy อนุญาต distribution นี้ด้วย
resource "aws_cloudfront_origin_access_control" "frontend" {
  # ตั้งชื่อ OAC ตามโปรเจกต์และ environment
  name        = "${var.project_name}-${var.environment}-frontend-oac"
  description = "CloudFront access to the private frontend bucket."

  # ใช้ OAC นี้กับ S3
  origin_access_control_origin_type = "s3"

  # ลงลายเซ็นทุก request ที่ส่งไป S3 และใช้ HTTPS ในการเชื่อมต่อ
  signing_behavior = "always"

  # ใช้ลายเซ็น AWS Signature Version 4 เพื่อยืนยัน request
  signing_protocol = "sigv4"
}

# สร้าง CloudFront เป็นทางเข้าของหน้าเว็บ รูปภาพ และ API สมาชิก
resource "aws_cloudfront_distribution" "frontend" {
  # เปิดให้ distribution รับ request จากผู้ใช้
  enabled = true
  comment = "Private S3 frontend and member image delivery."

  # เมื่อเปิด URL รากของเว็บ เช่น https://dxxxx.cloudfront.net/
  # ให้แสดง index.html
  default_root_object = "index.html"

  # เลือกกลุ่ม edge locations ราคาต่ำเพื่อควบคุมต้นทุน
  # ผู้ใช้ทุกประเทศยังเข้าเว็บได้ แต่อาจได้รับบริการจากจุดที่ไกลกว่า
  price_class = "PriceClass_100"

  # ต้นทางสำหรับไฟล์หน้าเว็บและรูปภาพ
  origin {
    # ใช้ S3 regional endpoint ไม่ใช่ S3 website endpoint
    domain_name = var.bucket_regional_domain_name

    # ชื่ออ้างอิงต้นทางนี้ เพื่อให้ behavior เลือกส่ง request มาได้
    origin_id = "frontend-s3-origin"

    # ใช้ OAC ที่สร้างไว้เพื่อยืนยัน request ที่ส่งไป S3
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # ต้นทางสำหรับเรียก API สมาชิก
  origin {
    # hostname ของ API Gateway โดยไม่ใส่ https:// หรือ path
    domain_name = var.api_domain_name
    origin_id   = "members-api-origin"

    # เติมชื่อ stage ก่อน path เช่น /members จะถูกส่งไป /dev/members
    origin_path = "/${var.api_stage_name}"

    custom_origin_config {
      # ระบุพอร์ต HTTP ตามรูปแบบ configuration
      # แต่ไม่ใช้พอร์ตนี้ เพราะกำหนด https-only
      http_port = 80

      # ติดต่อ API Gateway ผ่าน HTTPS ที่พอร์ต 443 เท่านั้น
      https_port             = 443
      origin_protocol_policy = "https-only"

      # ใช้ TLS 1.2 ระหว่าง CloudFront กับ API Gateway
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  # กฎสำหรับส่ง path /members ไป API Gateway
  ordered_cache_behavior {
    path_pattern     = "/members"
    target_origin_id = "members-api-origin"

    # อนุญาต GET และ HEAD ผ่าน CloudFront
    # API Gateway ต้องรองรับ method ที่ผู้ใช้เรียกด้วย
    allowed_methods = ["GET", "HEAD"]

    # ระบุ methods ที่ใช้ cache ได้ แต่ policy ด้านล่างปิดการ cache ไว้
    cached_methods = ["GET", "HEAD"]

    # ถ้าผู้ใช้เข้า HTTP ให้เปลี่ยนไป HTTPS
    viewer_protocol_policy = "redirect-to-https"

    # เปิดการบีบอัด response ที่รองรับ เพื่อลดขนาดข้อมูล
    compress = true

    # CachingDisabled: ไม่เก็บ API response ใน CloudFront cache
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # AllViewerExceptHostHeader: ส่ง headers, cookies และ query strings ไป API
    # โดยเปลี่ยน Host ให้เป็น hostname ของ API Gateway
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  # กฎสำหรับส่ง path ใต้ /members/ เช่น /members/1 ไป API Gateway
  # เป็นเพียงการส่งต่อ path ไม่ได้สร้าง endpoint นี้ให้ API Gateway
  ordered_cache_behavior {
    path_pattern     = "/members/*"
    target_origin_id = "members-api-origin"

    # อนุญาต GET และ HEAD ผ่าน CloudFront
    allowed_methods = ["GET", "HEAD"]

    # ระบุ methods ที่ใช้ cache ได้ แต่ policy ด้านล่างปิดการ cache ไว้
    cached_methods = ["GET", "HEAD"]

    # ถ้าผู้ใช้เข้า HTTP ให้เปลี่ยนไป HTTPS
    viewer_protocol_policy = "redirect-to-https"

    # เปิดการบีบอัด response ที่รองรับ
    compress = true

    # CachingDisabled: ไม่เก็บ API response ใน CloudFront cache
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # ส่งข้อมูล request ไป API โดยใช้ Host ของ API Gateway
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  # กฎสำหรับ path ที่ไม่ตรงกับ API behaviors ด้านบน
  # เช่น /, /assets/app.js และ /images/member.jpg
  default_cache_behavior {
    # ส่ง request ไปอ่านไฟล์จาก S3
    target_origin_id = "frontend-s3-origin"

    # อนุญาตให้อ่านไฟล์ด้วย GET และ HEAD และเก็บ response ใน cache ได้
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    # ถ้าผู้ใช้เข้า HTTP ให้เปลี่ยนไป HTTPS
    viewer_protocol_policy = "redirect-to-https"

    # เปิดการบีบอัดไฟล์ที่รองรับ เช่น HTML, CSS และ JavaScript
    compress = true

    forwarded_values {
      # ไม่ส่ง query string ไป S3 และไม่ใช้แยก cache
      # เช่น app.js?v=1 และ app.js?v=2 จะใช้ cache เดียวกัน
      query_string = false

      cookies {
        # ไม่ส่ง cookies ไป S3 และไม่ใช้แยก cache
        forward = "none"
      }
    }

    # อนุญาตให้อายุ cache ต่ำสุดเป็น 0 วินาที
    min_ttl = 0

    # ใช้อายุ cache 1 ชั่วโมง ถ้า S3 ไม่ส่ง header กำหนดอายุ cache
    default_ttl = 3600

    # จำกัดอายุ cache สูงสุดไว้ที่ 1 วัน
    max_ttl = 86400
  }

  restrictions {
    geo_restriction {
      # อนุญาตผู้ใช้จากทุกประเทศ
      restriction_type = "none"
    }
  }

  # เปิด HTTPS ด้วย certificate ที่ AWS จัดการให้สำหรับ *.cloudfront.net
  # ใช้ URL ของ CloudFront ได้โดยไม่ต้องซื้อโดเมนหรือสร้าง ACM certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}