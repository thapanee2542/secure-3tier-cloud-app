output "api_id" {
  # อธิบาย output api_id สำหรับผู้เรียกโมดูล
  description = "REST API identifier available independently of its Lambda integration."
  # ส่งออกID ของ REST API โดยไม่รอ Lambda integration เพื่อหลีกเลี่ยง dependency cycle
  value = aws_api_gateway_rest_api.members.id
}

output "api_name" {
  # อธิบาย output api_name สำหรับผู้เรียกโมดูล
  description = "REST API name used by CloudWatch alarm dimensions."
  # ส่งออกชื่อ REST API ที่ CloudWatch ใช้เลือก metrics
  value = aws_api_gateway_rest_api.members.name
}

output "stage_name" {
  # อธิบาย output stage_name สำหรับผู้เรียกโมดูล
  description = "Deployed stage name used by CloudWatch alarm dimensions."
  # ส่งออกชื่อ API stage ที่ deploy แล้ว
  value = aws_api_gateway_stage.members.stage_name
}

output "members_api_url" {
  # อธิบาย output members_api_url สำหรับผู้เรียกโมดูล
  description = "Direct URL for GET /members."
  # ส่งออกURL ของ GET /members ที่เรียก API Gateway โดยตรง
  value = "${aws_api_gateway_stage.members.invoke_url}${aws_api_gateway_resource.members.path}"
}