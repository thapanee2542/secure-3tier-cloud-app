output "base_url" {
  # อธิบาย output base_url สำหรับผู้เรียกโมดูล
  description = "HTTPS base URL for the distribution."
  # ส่งออกHTTPS URL ของ CloudFront สำหรับเปิดเว็บและรูปสมาชิก
  value = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "distribution_arn" {
  # อธิบาย output distribution_arn สำหรับผู้เรียกโมดูล
  description = "Distribution ARN used to restrict the S3 bucket policy."
  # ส่งออกARN ของ CloudFront ที่ใช้จำกัด S3 bucket policy
  value = aws_cloudfront_distribution.frontend.arn
}