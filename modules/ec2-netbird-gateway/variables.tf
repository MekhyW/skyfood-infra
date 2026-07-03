variable "name" {
  description = "Name prefix used for all resources in this module."
  type        = string
}

variable "vpc_id" {
  description = "VPC in which to place the gateway instance."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the gateway instance. Must have a route to an internet gateway so the instance can reach app.netbird.io."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the gateway."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH access. Set to null to disable SSH."
  type        = string
  default     = null
}

variable "ssh_allowed_cidr" {
  description = "CIDR that is allowed to reach port 22. Only relevant when key_name is set."
  type        = string
  default     = "0.0.0.0/0"
}

variable "netbird_setup_key" {
  description = "Netbird setup key used to auto-enroll the instance into the Netbird network."
  type        = string
  sensitive   = true
}

variable "netbird_management_url" {
  description = "URL of the Netbird management server."
  type        = string
  default     = "https://api.netbird.io"
}

variable "netbird_advertise_routes" {
  description = "Comma-separated list of CIDR routes the gateway will advertise to other Netbird peers. Use '0.0.0.0/0' to act as a default-route gateway."
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
