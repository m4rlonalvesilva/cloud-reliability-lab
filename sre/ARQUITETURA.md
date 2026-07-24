# Arquitetura — Fase Zabbix

## Atual (já no repositório)

```text
Internet
  → IGW
  → VPC 10.0.0.0/16
  → Subnet pública 10.0.1.0/24
  → SG (SSH 22 + opcional 6443 por CIDR; tráfego interno self)
       ├─ EC2[0]  Role=control-plane   kubeadm init + Calico
       └─ EC2[1]  Role=worker          kubeadm join (SSM)
```

## Alvo desta fase

```text
Internet
  → IGW
  → VPC / subnet pública (reutilizar)
  → Security groups (mínimo viável)
       │
       ├─ EC2 control-plane     K8s + zabbix-agent2
       ├─ EC2 worker            K8s + zabbix-agent2
       └─ EC2 zabbix-server     Zabbix Server + Frontend + DB + agent
              ↑
              UI :80 só allow_ssh_cidrs
              Agents → Server :10051 (rede interna / SG)
```

```text
Operador (browser)
    → http://ZABBIX_PUBLIC_IP/zabbix
         → vê métricas / problems dos 3 hosts
         → cria triggers, trata alertas (LAB-ALERTAS.md)

Operador (SSH)
    → drills em control-plane / worker
    → restore
```

## Evolução futura (não bloquear Zabbix)

```text
+ App sre-lab no Kubernetes
+ Kafka (preferência: no cluster)
+ Simulador WebLogic
+ Correlação / SLO / Game Days / auto-remediation
```

Zabbix continua o eixo de monitoração; novas tecnologias = novos hosts/templates/grupos (`Infrastructure`, `Kubernetes`, `Middleware`, …).

## Princípios

1. Reutilizar VPC/SSH/CIDR existentes  
2. Feature flag `enable_zabbix` para custo  
3. Roles Terraform separadas (K8s ≠ Zabbix)  
4. Secrets e `terraform.tfvars` fora do Git  
5. Documentação versionada em `sre/` (`docs/` local continua gitignored para notas pessoais)
