# ---------------------------------------------------------------------------
# Data: Latest Windows Server 2022 Full AMI
# ---------------------------------------------------------------------------
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
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
  name        = var.name
  description = "Windows service host: RDP, gRPC, Netbird WireGuard"
  vpc_id      = var.vpc_id

  # WireGuard – required for Netbird enrollment
  ingress {
    description = "WireGuard (Netbird)"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDP – open to all; access is gated by Netbird network membership
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # gRPC – open to all; access is gated by Netbird network membership
  ingress {
    description = "gRPC"
    from_port   = var.grpc_port
    to_port     = var.grpc_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Extra ingress rules (e.g. TKE UDP ports 8038-8041)
  dynamic "ingress" {
    for_each = var.extra_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = var.name })
}

# ---------------------------------------------------------------------------
# IAM – SSM access so you can open a session without RDP when needed
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
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}

# ---------------------------------------------------------------------------
# User Data – PowerShell bootstrap
# Installs SSM Agent (already present on Windows AMIs), optionally enrolls
# into Netbird. The .NET service and Softing OPC Suite must be installed
# manually via RDP after launch.
# ---------------------------------------------------------------------------
locals {
  netbird_block_enabled = <<-PS
    # ── Netbird ──────────────────────────────────────────────────────────────
    Write-Host "Installing Netbird..."
    $netbirdInstaller = "$env:TEMP\netbird-installer.exe"
    Invoke-WebRequest -Uri "https://pkgs.netbird.io/windows/x64/latest" `
                      -OutFile $netbirdInstaller -UseBasicParsing
    Start-Process -FilePath $netbirdInstaller -ArgumentList "/S" -Wait
    Start-Sleep -Seconds 5
    & "C:\Program Files\Netbird\netbird.exe" up `
        --setup-key "${var.netbird_setup_key}" `
        --management-url "${var.netbird_management_url}"
    Write-Host "Netbird enrolled."
  PS

  netbird_block = var.netbird_setup_key != null ? local.netbird_block_enabled : ""

  user_data = <<-PS
    <powershell>
    Set-ExecutionPolicy Bypass -Scope Process -Force
    $ErrorActionPreference = "Stop"

    # ── SSM Agent (ensure latest) ────────────────────────────────────────────
    Write-Host "Updating SSM Agent..."
    $ssm = "$env:TEMP\AmazonSSMAgentSetup.exe"
    Invoke-WebRequest -Uri "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe" `
                      -OutFile $ssm -UseBasicParsing
    Start-Process -FilePath $ssm -ArgumentList "/S" -Wait

    ${local.netbird_block}

    Write-Host "Bootstrap complete. RDP in to install Softing OPC Suite and deploy the ElevatorIntegrator service."
    </powershell>
  PS
}

# ---------------------------------------------------------------------------
# EC2 Instance
# ---------------------------------------------------------------------------
resource "aws_instance" "this" {
  ami                         = data.aws_ami.windows_2022.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.this.name
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.this.id]
  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    # Prevent replacement when a newer Windows AMI is published
    ignore_changes = [ami]
  }
}
