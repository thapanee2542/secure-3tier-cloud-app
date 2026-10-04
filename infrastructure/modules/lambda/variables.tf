variable "function_name" {
  # อธิบายหน้าที่ของตัวแปร function_name
  description = "Function name derived from the provisioned CloudWatch log group."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ function_name: string
  type = string
}

variable "execution_role_arn" {
  # อธิบายหน้าที่ของตัวแปร execution_role_arn
  description = "Execution role ARN with required policies attached."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ execution_role_arn: string
  type = string
}

variable "table_name" {
  # อธิบายหน้าที่ของตัวแปร table_name
  description = "DynamoDB table used by the handler."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ table_name: string
  type = string
}

variable "image_base_url" {
  # อธิบายหน้าที่ของตัวแปร image_base_url
  description = "CloudFront HTTPS base URL for member images."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ image_base_url: string
  type = string
}

variable "subnet_ids" {
  # อธิบายหน้าที่ของตัวแปร subnet_ids
  description = "Private subnet identifiers for Lambda."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ subnet_ids: list(string)
  type = list(string)
}

variable "security_group_id" {
  # อธิบายหน้าที่ของตัวแปร security_group_id
  description = "Security group allowing only DynamoDB HTTPS egress."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ security_group_id: string
  type = string
}

variable "source_file" {
  # อธิบายหน้าที่ของตัวแปร source_file
  description = "Path to the single Python handler to package, excluding tests."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ source_file: string
  type = string
}

variable "archive_path" {
  # อธิบายหน้าที่ของตัวแปร archive_path
  description = "Generated ZIP path in the root infrastructure directory."
  # กำหนดชนิดข้อมูลที่ยอมรับสำหรับ archive_path: string
  type = string
}