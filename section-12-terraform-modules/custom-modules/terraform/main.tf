module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "my-vpc"
}

module "subnet" {
  source                  = "./modules/subnet"
  vpc_id                  = module.vpc.vpc_id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  subnet_name             = "my-subnet"
}

