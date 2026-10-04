output "lambda_function_name" {
  # อธิบาย output lambda_function_name สำหรับผู้เรียกโมดูล
  description = "Lambda function name, waiting for the managed log group only when it is enabled."
  # ส่งออกชื่อ Lambda ที่ยังใช้งานได้แม้ปิดการสร้าง log group
  value = var.enable_log_group ? trimprefix(aws_cloudwatch_log_group.lambda[0].name, "/aws/lambda/") : "get-members"
}