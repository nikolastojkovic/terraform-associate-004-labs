output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.production.id
}

output "subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private.id
}

output "availability_zone" {
  description = "The availability zone of the private subnet"
  value       = aws_subnet.private.availability_zone
}

output "account_info" {
  description = "The AWS account ID"
  value       = "${data.aws_caller_identity.current.account_id}-(${data.aws_region.current.name})"
}