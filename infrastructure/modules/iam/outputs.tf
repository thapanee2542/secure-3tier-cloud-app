output "execution_role_arn" {
  # อธิบาย output execution_role_arn สำหรับผู้เรียกโมดูล
  description = "Lambda execution role ARN after its required policies are attached."
  # ส่งออกARN ของ Lambda execution role หลังติดตั้ง policy ที่จำเป็น
  value = aws_iam_role.lambda_execution.arn
  # ระบุ dependency ที่ต้องพร้อมก่อนใช้งานค่าหรือสร้าง resource นี้
  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy.members_table_scan,
  ]
}