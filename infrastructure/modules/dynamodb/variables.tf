variable "members" {
  # อธิบายหน้าที่ของตัวแปร members
  description = "Demo member records keyed by member ID."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ members: map(object({
  type = map(object({
    # ระบุรหัสนักศึกษาสำหรับข้อมูลสมาชิกและชื่อไฟล์รูป โดยใช้ string เพื่อรักษาเลขศูนย์นำหน้า
    studentId = string
    # ระบุชื่อสมาชิกในทีม
    name = string
    # ระบุบทบาทของสมาชิกในทีม
    role = string
  }))
}