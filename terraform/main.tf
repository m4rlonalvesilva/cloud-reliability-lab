# -----------------------------------------------------------------------------
# Infraestrutura base: VPC pública, 2x EC2 Ubuntu, SSH restrito por CIDR
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-${var.ubuntu_codename}-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  # Normaliza CRLF para LF para evitar "/usr/bin/env: bash\r" no cloud-init.
  k8s_common_sh          = replace(file("${path.module}/../kubernetes/scripts/common.sh"), "\r", "")
  k8s_install_components = replace(file("${path.module}/../kubernetes/scripts/install-k8s-components.sh"), "\r", "")
  k8s_control_plane_sh   = replace(file("${path.module}/../kubernetes/scripts/control-plane.sh"), "\r", "")
  k8s_worker_sh          = replace(file("${path.module}/../kubernetes/scripts/worker.sh"), "\r", "")
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security group: SSH apenas dos CIDRs informados ---
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "SSH restrito + egress para atualizacoes e diagnostico"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allow_ssh_cidrs
    content {
      description = "SSH from allowed CIDR"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.expose_kubernetes_api_https ? var.allow_ssh_cidrs : []
    content {
      description = "Kubernetes API (HTTPS) from same CIDRs as SSH - lab / kubectl local"
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  ingress {
    description = "Trafego interno entre nos do lab (cluster)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Permite saida para internet (apt, curl, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- EC2: N instâncias Ubuntu na subnet pública ---
resource "aws_instance" "app" {
  count = var.ec2_instance_count

  depends_on = [aws_ssm_parameter.k8s_join]

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = var.ec2_key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_k8s_bootstrap.name
  user_data_replace_on_change = true
  user_data                   = <<-EOT
    #!/usr/bin/env bash
    set -euxo pipefail
    exec > >(tee /var/log/k8s-bootstrap.log | logger -t k8s-bootstrap -s 2>/dev/console) 2>&1

    export AWS_DEFAULT_REGION="${var.aws_region}"
    export SSM_JOIN_PARAMETER_NAME="/${var.project_name}/k8s/join-command"

    cat >/tmp/common.sh <<'SCRIPT_COMMON'
    ${local.k8s_common_sh}
    SCRIPT_COMMON

    cat >/tmp/install-k8s-components.sh <<'SCRIPT_INSTALL'
    ${local.k8s_install_components}
    SCRIPT_INSTALL

    cat >/tmp/control-plane.sh <<'SCRIPT_CONTROL'
    ${local.k8s_control_plane_sh}
    SCRIPT_CONTROL

    cat >/tmp/worker.sh <<'SCRIPT_WORKER'
    ${local.k8s_worker_sh}
    SCRIPT_WORKER

    chmod +x /tmp/common.sh /tmp/install-k8s-components.sh /tmp/control-plane.sh /tmp/worker.sh

    /tmp/common.sh
    /tmp/install-k8s-components.sh

    if [ "${count.index}" -eq 0 ]; then
      /tmp/control-plane.sh
    else
      /tmp/worker.sh
    fi
  EOT

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-ubuntu-${count.index + 1}"
    Role = count.index == 0 ? "control-plane" : "worker"
  }
}
