# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "6.7.3"

#   name = var.vpc_name
#   cidr = var.cidr_block
# }

# module "security-group" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "6.0.0"

#   vpc_id = module.vpc.vpc_id
#   name   = "my-security-group"
# }


# module "s3-bucket" {
#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "5.17.0"

#   bucket_prefix           = "${var.environment}-modules-lab-"
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   versioning = {
#     enabled = true
#   }

#   tags = {
#     Environment = var.environment
#     Terraform   = "true"
#   }
# }

# Create one bucket for each name in the list
module "s3_buckets" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  for_each = toset(var.bucket_names) # <-- Create a bucket for each name in the list

  bucket_prefix = "${var.environment}-${each.value}-"

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Name        = each.value
  }
}