output "bucket_name" {
  # อธิบาย output bucket_name สำหรับผู้เรียกโมดูล
  description = "Name of the private frontend and member-image bucket."
  # ส่งออกชื่อ private S3 bucket สำหรับไฟล์เว็บและรูปสมาชิก
  value = aws_s3_bucket.frontend.bucket
}

output "bucket_regional_domain_name" {
  # อธิบาย output bucket_regional_domain_name สำหรับผู้เรียกโมดูล
  description = "Bucket regional domain available before the CloudFront access policy."
  # ส่งออกregional domain ของ S3 bucket โดยไม่รอ bucket policy เพื่อหลีกเลี่ยง cycle
  value = aws_s3_bucket.frontend.bucket_regional_domain_name
}