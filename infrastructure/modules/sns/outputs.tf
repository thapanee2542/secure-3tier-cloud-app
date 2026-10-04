output "topic_arn" {
  # อธิบาย output topic_arn สำหรับผู้เรียกโมดูล
  description = "SNS topic ARN for CloudWatch alarm actions."
  # ส่งออกARN ของ SNS topic สำหรับ alarm notifications
  value = aws_sns_topic.alarms.arn
}