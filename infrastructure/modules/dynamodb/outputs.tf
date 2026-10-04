output "table_name" {
  # อธิบาย output table_name สำหรับผู้เรียกโมดูล
  description = "Name of the encrypted members table."
  # ส่งออกชื่อ DynamoDB table สำหรับข้อมูลสมาชิก
  value = aws_dynamodb_table.members.name
}

output "table_arn" {
  # อธิบาย output table_arn สำหรับผู้เรียกโมดูล
  description = "Members table ARN for scoped IAM and endpoint policies."
  # ส่งออกARN ของ DynamoDB table สำหรับ IAM และ endpoint policy
  value = aws_dynamodb_table.members.arn
}