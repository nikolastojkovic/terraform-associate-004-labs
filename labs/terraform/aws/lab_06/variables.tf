variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "The environment for the resources"
  type        = string
  default     = "production"
}

variable "project" {
  description = "The project name for the resources"
  type        = string
  default     = "static-infrastructure"
}

variable "managed_by" {
  description = "The entity managing the resources"
  type        = string
  default     = "terraform"
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
  default     = "123456789"
}

variable "subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = string
  default     = "10.0.10.0/24"
}
