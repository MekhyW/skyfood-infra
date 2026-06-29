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
