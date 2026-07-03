variable "aws_region" {
  description = "AWS region used for this environment."
  type        = string
  default     = "sa-east-1"
}

variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
  default     = "skyfood"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the environment VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use. Keep two zones for the prototype to reduce cost while still supporting ALB."
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks. ECS services run here for the prototype and are only reachable through the ALB security group."
  type        = list(string)
  default     = ["10.40.0.0/24", "10.40.1.0/24"]
}

variable "container_services" {
  description = "Container services deployed to the shared ECS cluster and ALB."
  type = map(object({
    image             = string
    container_port    = optional(number, 3000)
    cpu               = optional(number, 256)
    memory            = optional(number, 512)
    desired_count     = optional(number, 1)
    health_check_path = optional(string, "/")
    path_patterns     = optional(list(string), ["/*"])
    environment       = optional(map(string), {})
    secrets           = optional(map(string), {})
  }))
}

variable "default_service_name" {
  description = "Service that receives the ALB default listener action. Leave null to use the first sorted service key."
  type        = string
  default     = null
}

variable "netbird_setup_key" {
  description = "Netbird setup key used to auto-enroll the EC2 gateway into the Netbird network."
  type        = string
  sensitive   = true
}

variable "netbird_management_url" {
  description = "Netbird management server URL."
  type        = string
  default     = "https://api.netbird.io"
}

variable "netbird_advertise_routes" {
  description = "CIDR routes the gateway advertises to all Netbird peers. Defaults to 0.0.0.0/0 so the EC2 acts as a catch-all gateway for robot traffic."
  type        = string
  default     = "0.0.0.0/0"
}

variable "netbird_gateway_instance_type" {
  description = "EC2 instance type for the Netbird gateway."
  type        = string
  default     = "t3.micro"
}

variable "netbird_gateway_key_name" {
  description = "Optional EC2 key pair name for SSH access to the gateway. Leave null to rely on SSM Session Manager only."
  type        = string
  default     = null
}
