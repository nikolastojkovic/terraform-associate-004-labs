output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "web_sg_id" {
  description = "The ID of the web security group"
  value       = aws_security_group.web.id
}

output "region" {
  description = "The AWS region where resources are deployed"
  value       = data.aws_region.current.name
}

