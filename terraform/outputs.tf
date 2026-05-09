# -----------------------------------------------------------------------------
# Outputs — IPs publicos para SSH e validacao no console
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID da VPC criada."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da subnet publica."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID do security group das EC2."
  value       = aws_security_group.ec2.id
}

output "ec2_instance_ids" {
  description = "IDs das instancias EC2."
  value       = aws_instance.app[*].id
}

output "ec2_public_ips" {
  description = "IPs publicos das instancias (ordem alinhada aos nomes ubuntu-1, ubuntu-2, ...)."
  value       = aws_instance.app[*].public_ip
}

output "control_plane_public_ip" {
  description = "IP publico do control-plane (indice 0); util para kubeconfig local e script import-kubeconfig-local.sh."
  value       = aws_instance.app[0].public_ip
}

output "kubeconfig_context_name" {
  description = "Nome sugerido para o contexto kubectl na sua maquina (sem colidir com outros clusters kubeadm). Usado por kubernetes/scripts/import-kubeconfig-local.sh."
  value       = lower(replace(replace(replace(var.project_name, " ", "-"), "_", "-"), ".", "-"))
}

output "kubernetes_api_exposed_https" {
  description = "Se a porta 6443 do apiserver está aberta aos CIDRs allow_ssh_cidrs (kubectl a partir do PC)."
  value       = var.expose_kubernetes_api_https
}

output "ec2_public_dns" {
  description = "DNS publico das instancias."
  value       = aws_instance.app[*].public_dns
}

output "ssh_hint" {
  description = "Comando sugerido para SSH (substitua usuario/chave conforme sua AMI)."
  value       = "ssh -i caminho/sua-chave.pem ubuntu@${aws_instance.app[0].public_ip}"
}

output "cluster_lab_generated_file" {
  description = "Caminho absoluto de cluster-lab.generated.txt (raiz do repositório: SSH + kubectl)."
  value       = abspath(local_file.cluster_lab.filename)
}
