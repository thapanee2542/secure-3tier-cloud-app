data "aws_caller_identity" "current" {}

module "vpc" {
  # เลือก local module vpc เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/vpc"
  # ส่งชื่อโปรเจกต์เพื่อใช้ตั้งชื่อ resource และขอบเขตของ policy
  project_name = var.project_name
  # ส่งชื่อ environment เพื่อแยกชื่อ resource และ tags แต่ไม่ได้แยก state โดยอัตโนมัติ
  environment = var.environment
  # ส่ง region สำหรับชื่อ resource และ service endpoint
  aws_region = var.aws_region
  # ระบุ ARN ของ DynamoDB table ที่ policy อนุญาตให้เข้าถึง
  table_arn = module.dynamodb.table_arn
  # ส่ง ARN ของ Lambda execution role ที่ติดตั้ง policy ที่จำเป็นแล้ว
  execution_role_arn = module.iam.execution_role_arn
}

module "dynamodb" {
  # เลือก local module dynamodb เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/dynamodb"
  # ส่งข้อมูลสมาชิกที่ใช้ member ID เป็น key เพื่อสร้าง DynamoDB records
  members = local.demo_members
}

module "iam" {
  # เลือก local module iam เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/iam"
  # ระบุ ARN ของ DynamoDB table ที่ policy อนุญาตให้เข้าถึง
  table_arn = module.dynamodb.table_arn
}

module "lambda" {
  # เลือก local module lambda เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/lambda"
  # ระบุชื่อ Lambda function ที่ใช้ deploy หรือกำหนดสิทธิ์ invocation
  function_name = module.cloudwatch.lambda_function_name
  # ส่ง ARN ของ Lambda execution role ที่ติดตั้ง policy ที่จำเป็นแล้ว
  execution_role_arn = module.iam.execution_role_arn
  # ระบุชื่อ DynamoDB table ที่ใช้อ่านหรือเขียนข้อมูลสมาชิก
  table_name = module.dynamodb.table_name
  # ส่ง HTTPS base URL ของ CloudFront ให้ Lambda สร้าง URL รูปสมาชิก
  image_base_url = module.cloudfront.base_url
  # ระบุ private subnets ที่ Lambda ใช้สร้าง network interfaces
  subnet_ids = [module.vpc.private_subnet_a_id, module.vpc.private_subnet_b_id]
  # ส่ง security group ที่จำกัด Lambda egress ไปยัง DynamoDB
  security_group_id = module.vpc.security_group_id
  # เลือกเฉพาะไฟล์ Python handler เพื่อสร้าง ZIP โดยไม่รวม tests หรือ virtual environment
  source_file = "${path.module}/../backend/get_members.py"
  # กำหนดตำแหน่งไฟล์ ZIP ที่สร้างใน infrastructure root
  archive_path = "${path.module}/get-members.zip"
}

module "api_gateway" {
  # เลือก local module api_gateway เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/api_gateway"
  # ส่งชื่อโปรเจกต์เพื่อใช้ตั้งชื่อ resource และขอบเขตของ policy
  project_name = var.project_name
  # ส่งชื่อ environment เพื่อแยกชื่อ resource และ tags แต่ไม่ได้แยก state โดยอัตโนมัติ
  environment = var.environment
  # กำหนด API stage สำหรับ routing สิทธิ์ invocation และ alarm dimensions
  api_stage_name = var.api_stage_name
  # ส่ง Lambda invocation ARN ให้ API Gateway proxy integration
  lambda_invoke_arn = module.lambda.invoke_arn
  # ส่งชื่อ Lambda function เพื่อกำหนดสิทธิ์ให้ API Gateway เรียกใช้งาน
  lambda_function_name = module.lambda.function_name
}

module "cloudfront" {
  # เลือก local module cloudfront เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/cloudfront"
  # ส่งชื่อโปรเจกต์เพื่อใช้ตั้งชื่อ resource และขอบเขตของ policy
  project_name = var.project_name
  # ส่งชื่อ environment เพื่อแยกชื่อ resource และ tags แต่ไม่ได้แยก state โดยอัตโนมัติ
  environment = var.environment
  # ส่ง regional domain ของ private S3 bucket ให้ CloudFront origin
  bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  # กำหนด domain ของ API Gateway โดยไม่รวม stage path
  api_domain_name = "${module.api_gateway.api_id}.execute-api.${var.aws_region}.amazonaws.com"
  # กำหนด API stage สำหรับ routing สิทธิ์ invocation และ alarm dimensions
  api_stage_name = var.api_stage_name
}

module "s3" {
  # เลือก local module s3 เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/s3"
  # ส่งชื่อโปรเจกต์เพื่อใช้ตั้งชื่อ resource และขอบเขตของ policy
  project_name = var.project_name
  # ส่งชื่อ environment เพื่อแยกชื่อ resource และ tags แต่ไม่ได้แยก state โดยอัตโนมัติ
  environment = var.environment
  # ส่งรหัสบัญชี AWS สำหรับชื่อ bucket และข้อจำกัดสิทธิ์ข้ามบริการ
  account_id = data.aws_caller_identity.current.account_id
  # ส่ง region สำหรับชื่อ resource และ service endpoint
  aws_region = var.aws_region
  # จำกัดสิทธิ์อ่าน S3 ให้ CloudFront distribution ที่กำหนด
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  # กำหนด directory รูปสมาชิกจาก root เพื่อไม่ให้ path เปลี่ยนเมื่อย้าย module
  image_directory = "${path.module}/files/images"
  # กำหนดชื่อไฟล์รูปและ key ที่คงที่สำหรับ S3 resources
  member_image_files = local.member_image_files
  # กำหนด directory ของ frontend build ที่จะอัปโหลด
  frontend_directory = "${path.module}/dist"
  # กำหนดชุดไฟล์ frontend build โดยรักษาชื่อไฟล์เป็น resource key
  frontend_files = local.frontend_files
  # กำหนดตาราง MIME types ตามนามสกุลไฟล์ frontend
  frontend_content_types = local.frontend_content_types
}

module "sns" {
  # สร้างหนึ่ง instance เมื่อ flag เป็น true และไม่สร้างเมื่อเป็น false ซึ่งอาจลบ resource เดิม
  count = var.enable_cloudwatch_alarms ? 1 : 0

  # เลือก local module sns เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/sns"
  # ส่งชื่อโปรเจกต์เพื่อใช้ตั้งชื่อ resource และขอบเขตของ policy
  project_name = var.project_name
  # ส่งชื่อ environment เพื่อแยกชื่อ resource และ tags แต่ไม่ได้แยก state โดยอัตโนมัติ
  environment = var.environment
  # ส่ง region สำหรับชื่อ resource และ service endpoint
  aws_region = var.aws_region
  # ส่งรหัสบัญชี AWS สำหรับชื่อ bucket และข้อจำกัดสิทธิ์ข้ามบริการ
  account_id = data.aws_caller_identity.current.account_id
  # กำหนดอีเมลผู้รับ alarm ซึ่งต้องยืนยัน SNS subscription ก่อนรับแจ้งเตือน
  notification_email = var.notification_email
}

module "cloudwatch" {
  # เลือก local module cloudwatch เพื่อจัดกลุ่ม AWS resources และเชื่อม dependency ผ่าน inputs
  source = "./modules/cloudwatch"
  # ส่งชื่อโปรเจกต์เพื่อใช้ตั้งชื่อ resource และขอบเขตของ policy
  project_name = var.project_name
  # ส่งชื่อ environment เพื่อแยกชื่อ resource และ tags แต่ไม่ได้แยก state โดยอัตโนมัติ
  environment = var.environment
  # ส่งชื่อ API Gateway ให้ CloudWatch เลือกชุด metric ที่ถูกต้อง
  api_name = module.api_gateway.api_name
  # กำหนด API stage สำหรับ routing สิทธิ์ invocation และ alarm dimensions
  api_stage_name = module.api_gateway.stage_name
  # ส่ง SNS topic ARN ให้ alarm ใช้แจ้งเตือน หรือ null เมื่อปิด alarms
  alarm_topic_arn = var.enable_cloudwatch_alarms ? module.sns[0].topic_arn : null
  # ควบคุมการสร้างและดูแล Lambda log group โดย Terraform
  enable_log_group = var.enable_cloudwatch_logs
  # ควบคุมการสร้าง API metric alarms ทั้งสองตัว
  enable_metric_alarms = var.enable_cloudwatch_alarms
}
