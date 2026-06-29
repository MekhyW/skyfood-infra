locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  service_keys = keys(var.container_services)

  default_service_name = coalesce(var.default_service_name, local.service_keys[0])

  service_rules = {
    for index, service_name in local.service_keys : service_name => {
      actions = [{forward = {target_group_key = service_name}}]
      conditions = [{path_pattern = {values = var.container_services[service_name].path_patterns}}]
      priority = 100 + index
    }
    if service_name != local.default_service_name
  }
}
