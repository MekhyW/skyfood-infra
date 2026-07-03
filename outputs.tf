output "alb_dns_name" {
  description = "Public DNS name for the shared application load balancer."
  value       = module.alb.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = module.ecs_cluster.name
}

output "service_names" {
  description = "ECS services deployed by this stack."
  value       = keys(module.ecs_service)
}

output "target_group_arns" {
  description = "Target groups keyed by service name."
  value = {
    for service_name, target_group in module.alb.target_groups : service_name => target_group.arn
  }
}

output "netbird_gateway_instance_id" {
  description = "EC2 instance ID of the Netbird gateway."
  value       = module.netbird_gateway.instance_id
}

output "netbird_gateway_public_ip" {
  description = "Public IP of the Netbird gateway. Enroll other peers against app.netbird.io; this IP is used internally by WireGuard."
  value       = module.netbird_gateway.public_ip
}

output "netbird_gateway_private_ip" {
  description = "Private IP of the Netbird gateway within the VPC."
  value       = module.netbird_gateway.private_ip
}
