# -----------------------------------------------------------------------------
# Permite ao control-plane publicar o comando kubeadm join no SSM Parameter Store
# e aos workers lê-lo (coordenação sem script local após o apply).
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  ssm_k8s_param_prefix_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/k8s/*"
}

resource "aws_iam_role" "ec2_k8s_bootstrap" {
  name = "${var.project_name}-ec2-k8s-bootstrap"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-ec2-k8s-bootstrap"
  }
}

resource "aws_iam_role_policy" "ec2_k8s_ssm_join" {
  name = "${var.project_name}-ec2-ssm-join"
  role = aws_iam_role.ec2_k8s_bootstrap.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "JoinParameterReadWrite"
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Resource = local.ssm_k8s_param_prefix_arn
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_k8s_bootstrap" {
  name = "${var.project_name}-ec2-k8s-bootstrap"
  role = aws_iam_role.ec2_k8s_bootstrap.name

  tags = {
    Name = "${var.project_name}-ec2-k8s-bootstrap"
  }
}
