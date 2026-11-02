# variable "cidr_block" {
#   description = "The CIDR block for the VPC."
#   type        = string
#   default     = "192.168.0.0/16"
# }

# variable "vpc_name" {
#   description = "The name of the VPC."
#   type        = string
#   default     = "my-terraform-vpc"
# }

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "bucket_names" {
  description = "Names for the additional S3 buckets"
  type        = list(string)
  default     = ["logs", "images"]
}