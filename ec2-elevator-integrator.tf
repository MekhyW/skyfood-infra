module "elevator_integrator" {
  source = "./modules/ec2-windows-service"

  name      = "${local.name}-elevator-integrator"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  instance_type       = var.elevator_integrator_instance_type
  key_name            = var.elevator_integrator_key_name
  root_volume_size_gb = 60

  grpc_port = 5000

  # TKE UDP communication ports
  extra_ingress_rules = [
    {
      description = "TKE UDP heartbeat broadcast"
      from_port   = 8038
      to_port     = 8038
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "TKE UDP heartbeat listen"
      from_port   = 8039
      to_port     = 8039
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "TKE UDP data listen"
      from_port   = 8040
      to_port     = 8040
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "TKE UDP data transmit"
      from_port   = 8041
      to_port     = 8041
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

  netbird_setup_key      = var.elevator_integrator_netbird_setup_key
  netbird_management_url = var.netbird_management_url

  tags = merge(local.tags, { Service = "elevator-integrator" })
}
