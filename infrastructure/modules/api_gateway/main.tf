terraform {
  required_providers {
    # ใช้ AWS provider ของ HashiCorp
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_api_gateway_rest_api" "members" {
  # ตั้งชื่อ API ตามชื่อโปรเจกต์และ environment เช่น my-project-dev-api
  name        = "${var.project_name}-${var.environment}-api"
  description = "Regional REST API for the members application."

  endpoint_configuration {
    # สร้าง API endpoint ใน AWS region ที่เลือก
    # เป็น public endpoint ไม่ใช่ Private API
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "members" {
  # สร้าง path ภายใน API ที่กำหนด
  rest_api_id = aws_api_gateway_rest_api.members.id

  # วาง path ไว้ใต้ root (/) ของ API
  parent_id = aws_api_gateway_rest_api.members.root_resource_id

  # สร้าง path /members
  path_part = "members"
}

resource "aws_api_gateway_method" "get_members" {
  # เลือก API และ path /members
  rest_api_id = aws_api_gateway_rest_api.members.id
  resource_id = aws_api_gateway_resource.members.id

  # เปิด endpoint GET /members สำหรับอ่านรายชื่อสมาชิก
  http_method = "GET"

  # เรียก API ได้โดยไม่ต้องยืนยันตัวตน
  authorization = "NONE"

  # เรียก API ได้โดยไม่ต้องส่ง API key
  api_key_required = false
}

resource "aws_api_gateway_integration" "get_members" {
  # เชื่อม GET /members กับ Lambda
  rest_api_id = aws_api_gateway_rest_api.members.id
  resource_id = aws_api_gateway_resource.members.id
  http_method = aws_api_gateway_method.get_members.http_method

  # API Gateway ใช้ POST เพื่อเรียก Lambda
  # แม้ผู้ใช้จะเรียก endpoint ด้วย GET
  integration_http_method = "POST"

  # ส่ง request ให้ Lambda แบบ proxy
  # Lambda ต้องคืน statusCode, headers และ body ตามรูปแบบ API Gateway
  type = "AWS_PROXY"

  # ARN สำหรับเรียก Lambda function ปลายทาง
  uri = var.lambda_invoke_arn
}

resource "aws_lambda_permission" "api_gateway_get_members" {
  # ชื่อกฎอนุญาตใน resource policy ของ Lambda
  statement_id = "AllowGetMembersFromApiGateway"

  # อนุญาตให้เรียกใช้ Lambda function นี้
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name

  # ให้สิทธิ์แก่บริการ API Gateway
  principal = "apigateway.amazonaws.com"

  # จำกัดสิทธิ์ให้เฉพาะ API นี้ ใน stage ที่กำหนด และเฉพาะ GET /members
  source_arn = "${aws_api_gateway_rest_api.members.execution_arn}/${var.api_stage_name}/GET/members"
}

resource "aws_api_gateway_deployment" "members" {
  # สร้าง snapshot ของการตั้งค่า API เพื่อให้ stage นำไปใช้งาน
  rest_api_id = aws_api_gateway_rest_api.members.id

  # เมื่อค่าที่รวมไว้ด้านล่างเปลี่ยน hash จะเปลี่ยน
  # ทำให้ Terraform สร้าง deployment ใหม่เพื่อเผยแพร่การตั้งค่าล่าสุด
  triggers = {
    redeployment = sha1(jsonencode({
      # ตรวจการเปลี่ยนประเภท endpoint และ path
      endpoint_types = aws_api_gateway_rest_api.members.endpoint_configuration[0].types
      path_part      = aws_api_gateway_resource.members.path_part

      # ตรวจการเปลี่ยน HTTP method, authentication และข้อกำหนด API key
      method = {
        http_method      = aws_api_gateway_method.get_members.http_method
        authorization    = aws_api_gateway_method.get_members.authorization
        api_key_required = aws_api_gateway_method.get_members.api_key_required
      }

      # ตรวจการเปลี่ยนวิธีเรียก Lambda, ชนิด integration และ Lambda ปลายทาง
      integration = {
        http_method = aws_api_gateway_integration.get_members.integration_http_method
        type        = aws_api_gateway_integration.get_members.type
        uri         = aws_api_gateway_integration.get_members.uri
      }
    }))
  }

  lifecycle {
    # สร้าง deployment ใหม่ก่อนลบตัวเก่า
    # เพื่อให้ stage ย้ายไปใช้ deployment ใหม่ได้ก่อน
    create_before_destroy = true
  }

  # รอให้ method และการเชื่อมต่อ Lambda สร้างเสร็จก่อน deploy API
  depends_on = [
    aws_api_gateway_method.get_members,
    aws_api_gateway_integration.get_members,
  ]
}

resource "aws_api_gateway_stage" "members" {
  # สร้าง stage และให้ใช้ API deployment ที่กำหนด
  rest_api_id   = aws_api_gateway_rest_api.members.id
  deployment_id = aws_api_gateway_deployment.members.id

  # ชื่อ stage เช่น dev ทำให้ URL เป็น /dev/members
  # CloudFront ใช้ค่านี้เป็น origin_path
  stage_name = var.api_stage_name

  # ไม่สร้าง API Gateway cache cluster
  cache_cluster_enabled = false

  # ไม่เปิด AWS X-Ray สำหรับติดตาม request
  xray_tracing_enabled = false
}

resource "aws_api_gateway_method_settings" "get_members" {
  # ใช้การตั้งค่ากับ API และ stage นี้
  rest_api_id = aws_api_gateway_rest_api.members.id
  stage_name  = aws_api_gateway_stage.members.stage_name

  # ใช้การตั้งค่าเฉพาะ GET /members
  method_path = "${aws_api_gateway_resource.members.path_part}/${aws_api_gateway_method.get_members.http_method}"

  settings {
    # ไม่เก็บ response ของ method นี้ใน API Gateway cache
    caching_enabled = false

    # ไม่เปิดการบันทึก request/response payload แบบละเอียดลง execution logs
    data_trace_enabled = false

    # ปิด execution logs ของ method นี้
    # ส่วน access logs ต้องตั้งค่าแยกที่ stage
    logging_level = "OFF"

    # ไม่เปิด detailed CloudWatch metrics ระดับ method
    # แต่ยังมี metrics พื้นฐานระดับ API
    metrics_enabled = false

    # รองรับ request ที่เข้ามาพร้อมกันเป็นช่วงสั้น ๆ ด้วย burst capacity 5
    throttling_burst_limit = 5

    # กำหนดอัตรารับ request เป้าหมาย 2 requests/วินาที
    # เมื่อเกินข้อจำกัด อาจได้รับ HTTP 429 Too Many Requests
    # เป็น best-effort throttling ไม่ใช่เพดานตายตัว
    throttling_rate_limit = 2
  }
}