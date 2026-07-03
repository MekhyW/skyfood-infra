# ---------------------------------------------------------------------------
# Data: Latest Amazon Linux 2023 AMI
# ---------------------------------------------------------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# Security Group
# ---------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.name}-netbird-gateway"
  description = "Netbird WireGuard gateway"
  vpc_id      = var.vpc_id

  # WireGuard – required for Netbird peer-to-peer tunnels
  ingress {
    description = "WireGuard (Netbird)"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optional SSH for operational access
  dynamic "ingress" {
    for_each = var.key_name != null ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_allowed_cidr]
    }
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-netbird-gateway" })
}

# ---------------------------------------------------------------------------
# IAM – SSM access (no SSH required for day-to-day ops)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-netbird-gateway"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-netbird-gateway"
  role = aws_iam_role.this.name
}

# ---------------------------------------------------------------------------
# EC2 Instance
# ---------------------------------------------------------------------------
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # ── 1. Kernel IP forwarding (required for gateway/routing mode) ──────────
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-netbird.conf
    sysctl -p /etc/sysctl.d/99-netbird.conf

    # ── 2. Install Netbird ───────────────────────────────────────────────────
    curl -fsSL https://pkgs.netbird.io/install.sh | sh

    # ── 3. Enable & start the Netbird daemon ────────────────────────────────
    systemctl enable netbird
    systemctl start netbird

    # ── 4. Enroll into the Netbird network and advertise routes ─────────────
    netbird up \
      --setup-key "${var.netbird_setup_key}" \
      --management-url "${var.netbird_management_url}" \
      --advertise-routes "${var.netbird_advertise_routes}"
  EOF
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.this.name
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.this.id]

  # Required so Netbird can forward packets between peers
  source_dest_check = false

  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, { Name = "${var.name}-netbird-gateway" })

  lifecycle {
    # Prevent replacement when a newer AL2023 AMI is published
    ignore_changes = [ami]
  }
}
