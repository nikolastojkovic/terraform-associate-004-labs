data "aws_region" "current" {}


locals {
  tags = {
    Environment = var.environment
    Project     = "terraform-demo"
    Owner       = "infrastructure-team"
    CostCenter  = "cc-1234"
    Region      = "${data.aws_region.current.name}"
    ManagedBy   = "terraform"
  }
  name_prefix = "${var.environment}-"
}

# Static configuration with repetitive elements
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, { Name = "${local.name_prefix}vpc" })
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = merge(local.tags, { Name = "${local.name_prefix}public-a" })
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = merge(local.tags, { Name = "${local.name_prefix}public-b" })
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = merge(local.tags, { Name = "${local.name_prefix}private-a" })
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = merge(local.tags, { Name = "${local.name_prefix}private-b" })
}

resource "aws_security_group" "web" {
  name        = "production-web-sg"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}web-sg" })
}