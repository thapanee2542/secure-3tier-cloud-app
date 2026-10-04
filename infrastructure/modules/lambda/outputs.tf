output "function_name" {
  # อธิบาย output function_name สำหรับผู้เรียกโมดูล
  description = "Lambda function name for the API invocation permission."
  # ส่งออกชื่อ Lambda function สำหรับให้ API Gateway invoke
  value = aws_lambda_function.get_members.function_name
}

output "invoke_arn" {
  # อธิบาย output invoke_arn สำหรับผู้เรียกโมดูล
  description = "Invocation ARN for API Gateway's proxy integration."
  # ส่งออกLambda invocation ARN สำหรับ API Gateway proxy integration
  value = aws_lambda_function.get_members.invoke_arn
}