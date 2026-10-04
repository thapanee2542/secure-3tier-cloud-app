variable "project_name" {
  # อธิบายหน้าที่ของตัวแปร project_name
  description = "Project prefix for the API name."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ project_name: string
  type = string
}

variable "environment" {
  # อธิบายหน้าที่ของตัวแปร environment
  description = "Environment prefix for the API name."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ environment: string
  type = string
}

variable "api_stage_name" {
  # อธิบายหน้าที่ของตัวแปร api_stage_name
  description = "Deployed API stage and scoped Lambda invocation stage."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ api_stage_name: string
  type = string
}

variable "lambda_invoke_arn" {
  # อธิบายหน้าที่ของตัวแปร lambda_invoke_arn
  description = "Lambda invocation ARN for the proxy integration."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ lambda_invoke_arn: string
  type = string
}

variable "lambda_function_name" {
  # อธิบายหน้าที่ของตัวแปร lambda_function_name
  description = "Function name receiving the scoped API invocation permission."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ lambda_function_name: string
  type = string
}