# -----------------------------------------------------------------------------
# Zabbix Server (EC2 dedicada) — opcional via enable_zabbix
# Independente do cluster K8s: monitoração continua se o cluster falhar.
# -----------------------------------------------------------------------------

locals {
  zabbix_stub_sh = replace(file("${path.module}/../sre/zabbix/scripts/bootstrap-stub.sh"), "\r", "")
}

# UI HTTP (:80) só dos mesmos CIDRs do SSH — nunca 0.0.0.0/0
resource "aws_security_group_rule" "zabbix_ui_http" {
  for_each = var.enable_zabbix ? toset(var.allow_ssh_cidrs) : toset([])

  type              = "ingress"
  security_group_id = aws_security_group.ec2.id
  description       = "Zabbix UI HTTP from allowed CIDR"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [each.value]
}

resource "aws_instance" "zabbix" {
  count = var.enable_zabbix ? 1 : 0

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.zabbix_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = var.ec2_key_name
  user_data_replace_on_change = true
  user_data                   = <<-EOT
    #!/usr/bin/env bash
    set -euxo pipefail

    cat >/tmp/zabbix-bootstrap-stub.sh <<'SCRIPT_ZABBIX'
    ${local.zabbix_stub_sh}
    SCRIPT_ZABBIX

    chmod +x /tmp/zabbix-bootstrap-stub.sh
    /tmp/zabbix-bootstrap-stub.sh
  EOT

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-zabbix"
    Role = "zabbix-server"
  }
}
