# Track SRE — Cloud Reliability Lab

Track de **SysOps + SRE** neste repositório. O track CKA (`kubernetes/labs/`) continua independente.

## Objetivo desta fase (Zabbix)

Após `terraform apply`, o laboratório sobe com **Zabbix acessível no browser**, hosts dos nós já monitorados, e guias para **criar, disparar, tratar e fechar alertas**.

```text
terraform apply
    → EC2 K8s (control-plane + worker) + EC2 Zabbix Server
    → Agents nos nós
    → UI Zabbix no teu IP (CIDR restrito)
    → Labs de alertas / incidentes Linux
terraform destroy   # sempre ao terminar
```

## Documentos

| Ficheiro | Conteúdo |
|----------|----------|
| [PLAN-ZABBIX.md](PLAN-ZABBIX.md) | Plano de implementação |
| [LAB-ALERTAS.md](LAB-ALERTAS.md) | Roteiro: criar e tratar alertas |
| [ARQUITETURA.md](ARQUITETURA.md) | Arquitetura alvo desta fase |
| [zabbix/00-PRIMEIRO-ACESSO-WIZARD.md](zabbix/00-PRIMEIRO-ACESSO-WIZARD.md) | Wizard DB (1.º acesso) |
| [zabbix/01-INSTALAR-AGENT.md](zabbix/01-INSTALAR-AGENT.md) | Instalar agent |
| [zabbix/04-CONFIGURAR-ALERTAS.md](zabbix/04-CONFIGURAR-ALERTAS.md) | Criar alertas na UI |
| [zabbix/05-BACKUP-E-RESTORE.md](zabbix/05-BACKUP-E-RESTORE.md) | **Destroy + retomar sem refazer alertas** |
| [zabbix/03-CENARIOS-VIDA-REAL.md](zabbix/03-CENARIOS-VIDA-REAL.md) | 12 cenários reais |
| [runbooks/](runbooks/) | Runbooks estilo produção |
| [drills/](drills/) | Scripts start/restore |

## Estado atual

| Item | Status |
|------|--------|
| VPC + 2× EC2 + kubeadm + Calico | Existe |
| Labs CKA | Existe (`kubernetes/labs/`) |
| Flag `enable_zabbix` + EC2 Zabbix + SG :80 + outputs | Feito |
| Instalação Zabbix Server + UI + wait script | **Passo 3 feito** |
| Agents nos nós K8s + hosts/templates + drills | **Passo 4+** (ver PLAN-ZABBIX) |

## Custo (ordem de grandeza, us-east-1)

- Base K8s: 2× `t3.small`
- + Zabbix Server: 1× `t3.small`
- Sessão típica 3–4 h: poucos dólares; **não esquecer `terraform destroy`**
