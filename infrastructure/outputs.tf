output "frontend_bucket_name" {
  # อธิบาย output frontend_bucket_name สำหรับผู้เรียกโมดูล
  description = "Name of the private S3 bucket shared by frontend files and member images."
  # ส่งออกชื่อ private S3 bucket สำหรับไฟล์เว็บและรูปสมาชิก
  value = module.s3.bucket_name
}

output "members_api_url" {
  # อธิบาย output members_api_url สำหรับผู้เรียกโมดูล
  description = "Direct URL for the deployed GET /members endpoint."
  # ส่งออกURL ของ GET /members ที่เรียก API Gateway โดยตรง
  value = module.api_gateway.members_api_url
}

output "cloudfront_base_url" {
  # อธิบาย output cloudfront_base_url สำหรับผู้เรียกโมดูล
  description = "HTTPS base URL for the CloudFront distribution serving the private bucket."
  # ส่งออกHTTPS URL ของ CloudFront สำหรับเปิดเว็บและรูปสมาชิก
  value = module.cloudfront.base_url
}

output "dynamodb_vpc_endpoint_id" {
  # อธิบาย output dynamodb_vpc_endpoint_id สำหรับผู้เรียกโมดูล
  description = "ID of the DynamoDB Gateway VPC endpoint."
  # ส่งออกID ของ DynamoDB Gateway endpoint
  value = module.vpc.dynamodb_vpc_endpoint_id
}

output "dynamodb_prefix_list_id" {
  # อธิบาย output dynamodb_prefix_list_id สำหรับผู้เรียกโมดูล
  description = "DynamoDB managed prefix list ID for this region."
  # ส่งออกID ของ DynamoDB prefix list ที่ใช้จำกัด network egress
  value = module.vpc.dynamodb_prefix_list_id
}

output "lambda_execution_role_arn" {
  # อธิบาย output lambda_execution_role_arn สำหรับผู้เรียกโมดูล
  description = "ARN of the Lambda execution role."
  # ส่งออกARN ของ Lambda execution role
  value = module.iam.execution_role_arn
}

output "alarm_topic_arn" {
  # อธิบาย output alarm_topic_arn สำหรับผู้เรียกโมดูล
  description = "SNS topic ARN for CloudWatch alarms, or null when alarms and notifications are disabled."
  # ส่งออกARN ของ SNS notifications หรือ null เมื่อปิด alarms
  value = var.enable_cloudwatch_alarms ? module.sns[0].topic_arn : null
}

output "private_route_table_id" {
  # อธิบาย output private_route_table_id สำหรับผู้เรียกโมดูล
  description = "ID of the route table shared by the private subnets."
  # ส่งออกID ของ route table ที่ private subnets ใช้ร่วมกัน
  value = module.vpc.private_route_table_id
}

output "private_subnet_a_id" {
  # อธิบาย output private_subnet_a_id สำหรับผู้เรียกโมดูล
  description = "ID of private subnet A."
  # ส่งออกID ของ private subnet แรก
  value = module.vpc.private_subnet_a_id
}

output "private_subnet_a_availability_zone" {
  # อธิบาย output private_subnet_a_availability_zone สำหรับผู้เรียกโมดูล
  description = "Availability Zone selected for private subnet A."
  # ส่งออกAvailability Zone ของ private subnet แรก
  value = module.vpc.private_subnet_a_availability_zone
}

output "private_subnet_b_id" {
  # อธิบาย output private_subnet_b_id สำหรับผู้เรียกโมดูล
  description = "ID of private subnet B."
  # ส่งออกID ของ private subnet ที่สอง
  value = module.vpc.private_subnet_b_id
}

output "private_subnet_b_availability_zone" {
  # อธิบาย output private_subnet_b_availability_zone สำหรับผู้เรียกโมดูล
  description = "Availability Zone selected for private subnet B."
  # ส่งออกAvailability Zone ของ private subnet ที่สอง
  value = module.vpc.private_subnet_b_availability_zone
}

output "vpc_id" {
  # อธิบาย output vpc_id สำหรับผู้เรียกโมดูล
  description = "ID of the project VPC."
  # ส่งออกID ของ VPC โปรเจกต์
  value = module.vpc.vpc_id
}