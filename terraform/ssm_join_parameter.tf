# -----------------------------------------------------------------------------
# Placeholder criado antes das EC2 e removido no terraform destroy.
# Evita que fique um "kubeadm join" de um cluster antigo e o worker novo falhe
# ao ler esse valor antes do novo control-plane publicar o join correto.
# O control-plane substitui o valor com PutParameter --overwrite.
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "k8s_join" {
  name        = "/${var.project_name}/k8s/join-command"
  description = "Placeholder até o control-plane correr kubeadm init; apagado no destroy."
  type        = "String"
  value       = "waiting-for-control-plane"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name = "${var.project_name}-k8s-join-command"
  }
}
