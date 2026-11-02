variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "The availability zone for the subnet."
  type        = string
  default     = "us-east-1a"
}

variable "map_public_ip_on_launch" {
  description = "Whether to map public IPs on launch for the subnet."
  type        = bool
  default     = true
}

variable "subnet_name" {
  description = "The name of the subnet."
  type        = string
  default     = "my-subnet"
}