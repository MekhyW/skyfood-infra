output "instance_id" {
  description = "ID of the Netbird gateway EC2 instance."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP address assigned to the gateway. Needed to whitelist the gateway in external firewalls."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the gateway within the VPC."
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "ID of the security group attached to the gateway instance."
  value       = aws_security_group.this.id
}
