# -----------------------------------------------------------------------------
# Ficheiro único na raiz do repo: cluster-lab.generated.txt (gitignored)
# Contém: inventário SSH (IPs + comandos) e lembrete kubectl no control-plane.
# -----------------------------------------------------------------------------

locals {
  cp_public_ip = aws_instance.app[0].public_ip

  cluster_lab_header = join("\n", [
    "# cluster-lab.generated.txt",
    "# Gerado por: terraform apply (não editar à mão — será sobrescrito)",
    "#",
    "# Comandos prontos: ajuste apenas o caminho da sua chave .pem.",
    "# Exemplo Git Bash: /c/Users/SEU_USUARIO/Documents/cloud-reliability-lab-key.pem",
    "#",
    "Projeto: ${var.project_name}",
    "Região:  ${var.aws_region}",
    "Key Pair (nome na AWS): ${var.ec2_key_name}",
    "Utilizador AMI Ubuntu: ubuntu",
    "Zabbix Server (enable_zabbix): ${var.enable_zabbix}",
    "",
  ])

  ssh_inventory_blocks = [
    for idx, inst in aws_instance.app : join("\n", [
      "────────────────────────────────────────────────────────────",
      "Nó ${idx + 1} — ${inst.tags.Name}",
      "  Função (tag Role): ${inst.tags.Role}",
      "  IP público:        ${inst.public_ip}",
      "  DNS público:       ${inst.public_dns}",
      "",
      "  SSH (ajuste o caminho da chave):",
      "    ssh -i SUA_CHAVE.pem -o StrictHostKeyChecking=accept-new ubuntu@${inst.public_ip}",
      "",
      "  Com variável (Git Bash):",
      "    export SSH_KEY_PATH=\"/c/Users/SEU_USUARIO/caminho/sua-chave.pem\"",
      "    ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new ubuntu@${inst.public_ip}",
      "",
    ])
  ]

  zabbix_inventory_section = var.enable_zabbix ? join("\n", [
    "────────────────────────────────────────────────────────────",
    "Zabbix Server — ${aws_instance.zabbix[0].tags.Name}",
    "  Função (tag Role): zabbix-server",
    "  IP público:        ${aws_instance.zabbix[0].public_ip}",
    "  IP privado:        ${aws_instance.zabbix[0].private_ip}",
    "  DNS público:       ${aws_instance.zabbix[0].public_dns}",
    "  URL UI (lab):      http://${aws_instance.zabbix[0].public_ip}/zabbix",
    "  Login lab:         Admin / zabbix  (alterar no 1.º acesso)",
    "",
    "  SSH:",
    "    ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new ubuntu@${aws_instance.zabbix[0].public_ip}",
    "",
    "  Esperar bootstrap + UI:",
    "    ./sre/zabbix/scripts/wait-for-zabbix.sh",
    "",
    "  Log de bootstrap:",
    "    sudo tail -f /var/log/zabbix-bootstrap.log",
    "",
    "  Acesso: sre/zabbix/ACCESS.md  |  Alertas: sre/LAB-ALERTAS.md",
    "",
    ]) : join("\n", [
    "────────────────────────────────────────────────────────────",
    "Zabbix Server: desligado (enable_zabbix = false)",
    "  Para ligar: enable_zabbix = true em terraform.tfvars e terraform apply",
    "  Plano: sre/PLAN-ZABBIX.md",
    "",
  ])

  cluster_lab_kubectl_section = join("\n", [
    "",
    "COMANDOS RÁPIDOS (Git Bash, na raiz do repositório):",
    "  export SSH_KEY_PATH=\"/c/Users/SEU_USUARIO/Documents/cloud-reliability-lab-key.pem\"",
    "  ./kubernetes/scripts/wait-for-cluster.sh",
    "  # publica Lab 01 (kubernetes/labs/01-objects): namespace lab-objects-01 + ~/cka-labs/01-objects",
    "",
    "================================================================================",
    "kubectl no control-plane (mesmo IP do nó com Role: control-plane acima)",
    "================================================================================",
    "",
    "# O cluster é criado no primeiro boot das EC2 (cloud-init): kubeadm init, join",
    "# via SSM Parameter Store, e Calico. Tempo típico até 2 nós Ready: ~3 min (README).",
    "# Acompanhe: ssh no control-plane e veja sudo tail -f /var/log/k8s-bootstrap.log",
    "#",
    "Control-plane (onde corre o kubectl): IP ${local.cp_public_ip}",
    "",
    "1) SSH (ajuste o caminho da chave .pem):",
    "   ssh -i \"$SSH_KEY_PATH\" -o StrictHostKeyChecking=accept-new ubuntu@${local.cp_public_ip}",
    "",
    "2) No servidor, o utilizador ubuntu já tem ~/.kube/config (após o bootstrap).",
    "   kubectl get nodes -o wide",
    "   kubectl get pods -A",
    "",
    "   kubectl na sua máquina (fora do SSH): em terraform.tfvars use",
    "   expose_kubernetes_api_https = true, terraform apply, depois na raiz do repo:",
    "   export SSH_KEY_PATH=\".../sua-chave.pem\"",
    "   ./kubernetes/scripts/import-kubeconfig-local.sh",
    "   export KUBECONFIG=\"$HOME/.kube/config:$(pwd)/.kube-generated/<slug>.yaml\"",
    "",
    "3) Se kubectl disser que não há config ainda, o bootstrap ainda está a correr ou falhou.",
    "   sudo tail -100 /var/log/k8s-bootstrap.log",
    "",
  ])
}

resource "local_file" "cluster_lab" {
  filename = "${path.module}/../cluster-lab.generated.txt"
  content  = "${local.cluster_lab_header}${join("\n", local.ssh_inventory_blocks)}${local.zabbix_inventory_section}${local.cluster_lab_kubectl_section}"
}
