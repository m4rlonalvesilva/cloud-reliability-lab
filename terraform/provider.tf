# -----------------------------------------------------------------------------
# Provider AWS e versões mínimas do Terraform
# Credenciais: use AWS CLI (aws configure) ou variáveis de ambiente — nunca
# coloque access keys neste repositório.
# -----------------------------------------------------------------------------

terraform {
  # Compatível com instalações comuns no Windows; recomendado >= 1.5 para novos labs
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Tags padrão em todos os recursos que suportam tagging
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
