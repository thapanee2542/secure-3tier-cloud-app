locals {
  # ค้นหาไฟล์ทั้งหมดใน dist รวม subdirectories สำหรับอัปโหลด frontend
  frontend_files = fileset("${path.module}/dist", "**")

  # กำหนดตาราง MIME types ตามนามสกุลไฟล์ frontend
  frontend_content_types = {
    # กำหนด MIME type ของไฟล์ HTML เพื่อให้ browser อ่านถูกชนิด
    html = "text/html; charset=utf-8"
    # กำหนด MIME type ของไฟล์ CSS เพื่อให้ browser อ่านถูกชนิด
    css = "text/css; charset=utf-8"
    # กำหนด MIME type ของไฟล์ JavaScript เพื่อให้ browser อ่านถูกชนิด
    js = "text/javascript; charset=utf-8"
    # กำหนด MIME type ของไฟล์ JavaScript module เพื่อให้ browser อ่านถูกชนิด
    mjs = "text/javascript; charset=utf-8"
    # กำหนด MIME type ของไฟล์ JSON เพื่อให้ browser อ่านถูกชนิด
    json = "application/json"
    # กำหนด MIME type ของไฟล์ SVG เพื่อให้ browser อ่านถูกชนิด
    svg = "image/svg+xml"
    # กำหนด MIME type ของไฟล์ PNG เพื่อให้ browser อ่านถูกชนิด
    png = "image/png"
    # กำหนด MIME type ของไฟล์ JPEG เพื่อให้ browser อ่านถูกชนิด
    jpg = "image/jpeg"
    # กำหนด MIME type ของไฟล์ JPEG เพื่อให้ browser อ่านถูกชนิด
    jpeg = "image/jpeg"
    # กำหนด MIME type ของไฟล์ PDF เพื่อให้ browser อ่านถูกชนิด
    pdf = "application/pdf"
    # กำหนด MIME type ของไฟล์ ไอคอน เพื่อให้ browser อ่านถูกชนิด
    ico = "image/vnd.microsoft.icon"
    # กำหนด MIME type ของไฟล์ WebP เพื่อให้ browser อ่านถูกชนิด
    webp = "image/webp"
    # กำหนด MIME type ของไฟล์ ฟอนต์ WOFF เพื่อให้ browser อ่านถูกชนิด
    woff = "font/woff"
    # กำหนด MIME type ของไฟล์ ฟอนต์ WOFF2 เพื่อให้ browser อ่านถูกชนิด
    woff2 = "font/woff2"
  }

  # ค้นหาเฉพาะรูป JPG และ JPEG โดยเก็บชื่อไฟล์เป็น key ที่คงที่
  member_image_files = {
    for filename in fileset("${path.module}/files/images", "*") : filename => filename
    if endswith(lower(filename), ".jpg") || endswith(lower(filename), ".jpeg")
  }
}

locals {
  # กำหนดข้อมูลสมาชิกตัวอย่างที่ Terraform สร้างและดูแลใน DynamoDB
  demo_members = {
    # กำหนด member ID 1 เป็น key ของ record โดยไม่ใช้ลำดับใน list
    "1" = {
      # ระบุรหัสนักศึกษาสำหรับข้อมูลสมาชิกและชื่อไฟล์รูป โดยใช้ string เพื่อรักษาเลขศูนย์นำหน้า
      studentId = "6907031857211"
      # ระบุชื่อสมาชิกในทีม
      name = "Thapanee Nooying"
      # ระบุบทบาทของสมาชิกในทีม
      role = "Developer"
    }
    # กำหนด member ID 2 เป็น key ของ record โดยไม่ใช้ลำดับใน list
    "2" = {
      # ระบุรหัสนักศึกษาสำหรับข้อมูลสมาชิกและชื่อไฟล์รูป โดยใช้ string เพื่อรักษาเลขศูนย์นำหน้า
      studentId = "6907031857148"
      # ระบุชื่อสมาชิกในทีม
      name = "Suttisak Nayakovit"
      # ระบุบทบาทของสมาชิกในทีม
      role = "Frontend Developer"
    }
    # กำหนด member ID 3 เป็น key ของ record โดยไม่ใช้ลำดับใน list
    "3" = {
      # ระบุรหัสนักศึกษาสำหรับข้อมูลสมาชิกและชื่อไฟล์รูป โดยใช้ string เพื่อรักษาเลขศูนย์นำหน้า
      studentId = "6907031857164"
      # ระบุชื่อสมาชิกในทีม
      name = "Anutta Bunklom"
      # ระบุบทบาทของสมาชิกในทีม
      role = "Backend Developer"
    }
    # กำหนด member ID 4 เป็น key ของ record โดยไม่ใช้ลำดับใน list
    "4" = {
      # ระบุรหัสนักศึกษาสำหรับข้อมูลสมาชิกและชื่อไฟล์รูป โดยใช้ string เพื่อรักษาเลขศูนย์นำหน้า
      studentId = "6907031857181"
      # ระบุชื่อสมาชิกในทีม
      name = "Bhornmarda Wongwai"
      # ระบุบทบาทของสมาชิกในทีม
      role = "Backend Developer"
    }
    # กำหนด member ID 5 เป็น key ของ record โดยไม่ใช้ลำดับใน list
    "5" = {
      # ระบุรหัสนักศึกษาสำหรับข้อมูลสมาชิกและชื่อไฟล์รูป โดยใช้ string เพื่อรักษาเลขศูนย์นำหน้า
      studentId = "6907031857229"
      # ระบุชื่อสมาชิกในทีม
      name = "Suphach Thayakornwiwat"
      # ระบุบทบาทของสมาชิกในทีม
      role = "Backend Developer"
    }
  }
}