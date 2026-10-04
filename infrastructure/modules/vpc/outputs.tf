output "vpc_id" {
  # อธิบาย output vpc_id สำหรับผู้เรียกโมดูล
  description = "Project VPC identifier."
  # ส่งออกID ของ VPC โปรเจกต์
  value = aws_vpc.main.id
}

output "private_route_table_id" {
  # อธิบาย output private_route_table_id สำหรับผู้เรียกโมดูล
  description = "Private route table identifier."
  # ส่งออกID ของ route table ที่ private subnets ใช้ร่วมกัน
  value = aws_route_table.private.id
}

output "private_subnet_a_id" {
  # อธิบาย output private_subnet_a_id สำหรับผู้เรียกโมดูล
  description = "First private subnet identifier."
  # ส่งออกID ของ private subnet แรก
  value = aws_subnet.private_a.id
}

output "private_subnet_a_availability_zone" {
  # อธิบาย output private_subnet_a_availability_zone สำหรับผู้เรียกโมดูล
  description = "Availability Zone for the first private subnet."
  # ส่งออกAvailability Zone ของ private subnet แรก
  value = aws_subnet.private_a.availability_zone
}

output "private_subnet_b_id" {
  # อธิบาย output private_subnet_b_id สำหรับผู้เรียกโมดูล
  description = "Second private subnet identifier."
  # ส่งออกID ของ private subnet ที่สอง
  value = aws_subnet.private_b.id
}

output "private_subnet_b_availability_zone" {
  # อธิบาย output private_subnet_b_availability_zone สำหรับผู้เรียกโมดูล
  description = "Availability Zone for the second private subnet."
  # ส่งออกAvailability Zone ของ private subnet ที่สอง
  value = aws_subnet.private_b.availability_zone
}

output "security_group_id" {
  # อธิบาย output security_group_id สำหรับผู้เรียกโมดูล
  description = "Security group limiting Lambda egress to DynamoDB HTTPS."
  # ส่งออกID ของ security group ที่จำกัด Lambda egress
  value = aws_security_group.lambda.id
}

output "dynamodb_vpc_endpoint_id" {
  # อธิบาย output dynamodb_vpc_endpoint_id สำหรับผู้เรียกโมดูล
  description = "DynamoDB Gateway endpoint identifier."
  # ส่งออกID ของ DynamoDB Gateway endpoint
  value = aws_vpc_endpoint.dynamodb.id
}

output "dynamodb_prefix_list_id" {
  # อธิบาย output dynamodb_prefix_list_id สำหรับผู้เรียกโมดูล
  description = "DynamoDB managed prefix list identifier."
  # ส่งออกID ของ DynamoDB prefix list ที่ใช้จำกัด network egress
  value = aws_vpc_endpoint.dynamodb.prefix_list_id
}