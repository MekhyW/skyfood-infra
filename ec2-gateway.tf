module "netbird_gateway" {
  source                   = "./modules/ec2-netbird-gateway"
  name                     = "${local.name}-gateway"
  vpc_id                   = module.vpc.vpc_id
  subnet_id                = module.vpc.public_subnets[0]
  instance_type            = var.netbird_gateway_instance_type
  key_name                 = var.netbird_gateway_key_name
  netbird_setup_key        = var.netbird_setup_key
  netbird_management_url   = var.netbird_management_url
  netbird_advertise_routes = var.netbird_advertise_routes
  tags                     = local.tags
}
