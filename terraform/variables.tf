# -----------------------------------------------------------------------------
# Variáveis do laboratório — valores sensíveis ficam em terraform.tfvars (local)
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "Região AWS onde os recursos serão criados. Padrao do lab: us-east-1 (N. Virginia) — em geral precos de referencia e ampla disponibilidade de AMIs/servicos; ajuste se quiser menor latencia (ex.: sa-east-1 no Brasil)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome lógico do projeto; usado em tags e nomes de recursos."
  type        = string
  default     = "cloud-reliability-lab"
}

variable "environment" {
  description = "Ambiente (ex: lab, dev) — útil para tags e governança."
  type        = string
  default     = "lab"
}

variable "vpc_cidr" {
  description = "CIDR da VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública (deve estar dentro do vpc_cidr)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "allow_ssh_cidrs" {
  description = "Lista de CIDRs com permissão para SSH (22). Use seu IP público em /32. Evite 0.0.0.0/0 em produção."
  type        = list(string)
  # Sem default intencional: force o preenchimento em terraform.tfvars
}

variable "expose_kubernetes_api_https" {
  description = "Se true, abre TCP 6443 (kube-apiserver) a partir dos mesmos CIDRs que allow_ssh_cidrs, para usar kubectl na sua máquina (fora do SSH). Mantenha false se só usar kubectl via SSH."
  type        = bool
  default     = false
}

variable "ec2_key_name" {
  description = "Nome do Key Pair já existente na região (criado no console AWS ou via CLI)."
  type        = string
}

variable "instance_type" {
  description = "Tipo de instância EC2 (t3.micro costuma ser elegível ao free tier onde aplicável)."
  type        = string
  default     = "t3.micro"
}

variable "ec2_instance_count" {
  description = "Quantidade de instâncias Ubuntu (Fase 1: 2)."
  type        = number
  default     = 2

  validation {
    condition     = var.ec2_instance_count >= 1 && var.ec2_instance_count <= 5
    error_message = "Use entre 1 e 5 instâncias neste laboratório inicial."
  }
}

variable "ubuntu_codename" {
  description = "Filtro de nome da AMI Ubuntu (jammy = 22.04 LTS)."
  type        = string
  default     = "jammy"
}
