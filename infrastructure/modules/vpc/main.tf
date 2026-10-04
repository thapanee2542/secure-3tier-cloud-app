terraform {
  required_providers {
    # ใช้ AWS provider ของ HashiCorp
    # โดยรับ region และ credentials จาก provider ใน root module
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# สร้างเครือข่าย VPC สำหรับการเชื่อมต่อของ Lambda
resource "aws_vpc" "main" {
  # ชื่อที่แสดงใน AWS Console
  tags = {
    Name = "lambda-vpc"
  }

  # ช่วง IP ภายใน VPC: 10.0.0.0 ถึง 10.0.255.255
  cidr_block = "10.0.0.0/16"

  # เปิดให้ใช้ DNS resolver ของ AWS เพื่อแปลงชื่อบริการเป็น IP
  enable_dns_support = true

  # เปิดการรองรับ DNS hostnames ใน VPC
  enable_dns_hostnames = true

  # ใช้ tenancy ปกติ ไม่บังคับให้ EC2 ใช้ฮาร์ดแวร์แบบ dedicated
  instance_tenancy = "default"
}

# อ่านรายชื่อ Availability Zones ที่พร้อมใช้งานใน region นี้
# เป็นการอ่านข้อมูล ไม่ได้สร้าง AZ ใหม่
data "aws_availability_zones" "available" {
  state = "available"
}

# สร้าง subnet แรกสำหรับเชื่อม Lambda เข้ากับ VPC
resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id

  # ใช้ช่วง IP 10.0.1.0 ถึง 10.0.1.255 ภายใน VPC
  cidr_block = "10.0.1.0/24"

  # วาง subnet ใน AZ แรกจากรายชื่อที่อ่านได้
  availability_zone = data.aws_availability_zones.available.names[0]

  # ไม่แจก public IPv4 อัตโนมัติให้ EC2 ที่เปิดใน subnet นี้
  # ความเป็น private ยังขึ้นกับเส้นทางใน route table ด้วย
  map_public_ip_on_launch = false
}

# สร้าง subnet ที่สองในอีก AZ เพื่อให้ Lambda มีการเชื่อมต่อข้าม AZ
resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.main.id

  # ใช้ช่วง IP แยกจาก subnet แรก เพื่อไม่ให้ช่วง IP ซ้อนกัน
  cidr_block = "10.0.2.0/24"

  # วาง subnet ใน AZ ที่สอง ซึ่งต่างจาก private_a
  availability_zone = data.aws_availability_zones.available.names[1]

  # ไม่แจก public IPv4 อัตโนมัติให้ EC2 ที่เปิดใน subnet นี้
  map_public_ip_on_launch = false
}

# สร้าง route table ที่ทั้งสอง private subnets ใช้ร่วมกัน
# มีเส้นทางภายใน VPC โดยอัตโนมัติ แต่ไม่ได้เพิ่มเส้นทางออก Internet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

# ให้ subnet แรกใช้เส้นทางจาก private route table
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# ให้ subnet ที่สองใช้เส้นทางจาก private route table เดียวกัน
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ควบคุม traffic ผ่านการเชื่อมต่อ VPC ของ Lambda
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.environment}-lambda"
  description = "Security group for Lambda access to DynamoDB."
  vpc_id      = aws_vpc.main.id

  # ไม่เปิด inbound rules
  # การ invoke Lambda ผ่าน API Gateway ไม่ต้องเปิดพอร์ต inbound ใน SG นี้

  egress {
    description = "HTTPS to DynamoDB through the gateway endpoint."

    # อนุญาตให้เชื่อมต่อออกด้วย TCP พอร์ต 443 (HTTPS) เท่านั้น
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    # จำกัดปลายทางให้เป็นกลุ่ม IP ของ DynamoDB ใน region นี้
    # เส้นทางไปบริการจะผ่าน Gateway Endpoint ที่ผูกกับ route table
    prefix_list_ids = [aws_vpc_endpoint.dynamodb.prefix_list_id]
  }
}

# เพิ่มเส้นทางจาก private subnets ไป DynamoDB
# โดยไม่ต้องใช้ NAT Gateway หรือ Internet Gateway
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id = aws_vpc.main.id

  # เลือกบริการ DynamoDB ใน region ที่กำหนด
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"

  # ใช้ Gateway Endpoint ซึ่งทำงานผ่าน route table
  # ไม่ได้ย้าย DynamoDB เข้ามาอยู่ใน VPC
  vpc_endpoint_type = "Gateway"

  # เพิ่มเส้นทางไป DynamoDB ลงใน route table ของทั้งสอง private subnets
  route_table_ids = [aws_route_table.private.id]

  # จำกัดการใช้งาน DynamoDB ผ่าน endpoint นี้
  # ผู้เรียกยังต้องได้รับสิทธิ์จาก IAM policy ของตัวเองด้วย
  policy = jsonencode({
    # เวอร์ชันรูปแบบ IAM policy ไม่ใช่วันที่สร้าง
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      # ตรวจผู้เรียกทุกคน แต่ให้ผ่านเฉพาะ role ที่ตรงเงื่อนไขด้านล่าง
      Principal = "*"

      # อนุญาตให้อ่านรายการในตารางด้วย Scan
      # และอ่านรายการตามคีย์ด้วย GetItem
      Action = ["dynamodb:Scan", "dynamodb:GetItem"]

      # ใช้ได้เฉพาะตารางที่ระบุ ARN นี้
      Resource = var.table_arn

      Condition = {
        StringEquals = {
          # ให้ผ่านเฉพาะผู้เรียกที่ใช้ Lambda execution role ของโปรเจกต์
          "aws:PrincipalArn" = var.execution_role_arn
        }
      }
    }]
  })
}