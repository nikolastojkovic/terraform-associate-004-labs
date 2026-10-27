# Static configuration with hardcoded values
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "production" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-vpc"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "manual-deployment"
    Region      = data.aws_region.current.name
    AccountID   = data.aws_caller_identity.current.account_id
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project}-private-subnet"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Region      = data.aws_region.current.name
    AZ          = data.aws_availability_zones.available.names[0]
  }
}

resource "aws_route_table" "static" {
  vpc_id = aws_vpc.production.id

  tags = {
    Name        = "${var.project}-route-table"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Region      = data.aws_region.current.name
  }
}