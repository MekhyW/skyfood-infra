module "ecs_cluster" {
  source = "../../modules/container-service/modules/cluster"
  name = "${local.name}-cluster"
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_name              = "/aws/ecs/${local.name}"
  cloudwatch_log_group_retention_in_days = 14
  setting = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]
  tags = local.tags
}

module "ecs_service" {
  source = "../../modules/container-service/modules/service"

  for_each = var.container_services

  name        = each.key
  cluster_arn = module.ecs_cluster.arn
  tags        = merge(local.tags, {Service = each.key})

  cpu           = each.value.cpu
  memory        = each.value.memory
  desired_count = each.value.desired_count

  launch_type                       = "FARGATE"
  requires_compatibilities          = ["FARGATE"]
  network_mode                      = "awsvpc"
  assign_public_ip                  = true
  subnet_ids                        = module.vpc.public_subnets
  health_check_grace_period_seconds = 30

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups[each.key].arn
      container_name   = each.key
      container_port   = each.value.container_port
    }
  }

  container_definitions = {
    (each.key) = {
      image     = each.value.image
      essential = true

      portMappings = [
        {
          name          = each.key
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for name, value in each.value.environment : {
          name  = name
          value = value
        }
      ]

      secrets = [
        for name, value_from in each.value.secrets : {
          name      = name
          valueFrom = value_from
        }
      ]

      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/${local.name}/${each.key}"
      cloudwatch_log_group_retention_in_days = 14
      readonlyRootFilesystem                 = false
    }
  }

  security_group_ingress_rules = {
    alb = {
      description                  = "Traffic from shared ALB"
      from_port                    = each.value.container_port
      to_port                      = each.value.container_port
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.alb.security_group_id
    }
  }

  security_group_egress_rules = {
    all = {
      description = "All outbound"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}
