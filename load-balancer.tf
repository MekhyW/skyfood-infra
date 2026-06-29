module "alb" {
  source = "./modules/load-balancer"

  name               = local.name
  tags               = local.tags
  load_balancer_type = "application"
  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

  security_group_ingress_rules = {
    http = {
      description = "Public HTTP"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      description = "All outbound"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward  = { target_group_key = local.default_service_name }
      rules    = local.service_rules
    }
  }

  target_groups = {
    for service_name, service in var.container_services : service_name => {
      name              = substr("${local.name}-${service_name}", 0, 32)
      protocol          = "HTTP"
      port              = service.container_port
      target_type       = "ip"
      vpc_id            = module.vpc.vpc_id
      create_attachment = false
      health_check = {
        enabled             = true
        path                = service.health_check_path
        matcher             = "200-399"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }
}
