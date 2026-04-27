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

output "ec2_public_dns" {
  description = "DNS publico das instancias."
  value       = aws_instance.app[*].public_dns
}

output "ssh_hint" {
  description = "Comando sugerido para SSH (substitua usuario/chave conforme sua AMI)."
  value       = "ssh -i caminho/sua-chave.pem ubuntu@${aws_instance.app[0].public_ip}"
}
