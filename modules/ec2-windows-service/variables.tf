variable "name" {
  description = "Name prefix used for all resources in this module."
  type        = string
}

variable "vpc_id" {
  description = "VPC in which to place the instance."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the instance."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. Windows requires at least t3.medium for a comfortable experience."
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Optional EC2 key pair name. Used to decrypt the Windows Administrator password via the console."
  type        = string
  default     = null
}

variable "rdp_allowed_cidrs" {
  description = "Deprecated – kept for compatibility. RDP is now open to 0.0.0.0/0 and access is gated by Netbird."
  type        = list(string)
  default     = []
}

variable "grpc_port" {
  description = "TCP port the gRPC service listens on."
  type        = number
  default     = 5000
}

variable "extra_ingress_rules" {
  description = "Additional ingress rules (e.g. TKE UDP ports). Each object must have from_port, to_port, protocol, and cidr_blocks."
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "netbird_setup_key" {
  description = "Netbird setup key to auto-enroll the instance. Set to null to skip Netbird installation."
  type        = string
  default     = null
  sensitive   = true
}

variable "netbird_management_url" {
  description = "URL of the Netbird management server."
  type        = string
  default     = "https://api.netbird.io"
}

variable "root_volume_size_gb" {
  description = "Size of the root EBS volume in GiB. Windows needs at least 30 GB."
  type        = number
  default     = 50
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
