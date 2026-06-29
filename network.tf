module "vpc" {
  source = "../../modules/vpc"
  name = local.name
  cidr = var.vpc_cidr
  azs = var.availability_zones
  public_subnets = var.public_subnets
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_nat_gateway = false
  public_subnet_tags = {Tier = "public"}
  tags = local.tags
}
