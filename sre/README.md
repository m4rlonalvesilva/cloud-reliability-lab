# Track SRE — Cloud Reliability Lab

Track de **SysOps + SRE**. O track CKA (`kubernetes/labs/`) continua independente.

## Começa aqui

**Passo a passo Zabbix (completo):** [`zabbix/PASSO-A-PASSO.md`](zabbix/PASSO-A-PASSO.md)

```text
terraform apply
  → Zabbix 6.4.0 + K8s
  → agents + hosts + alertas
  → backup config → Git
  → terraform destroy          # controla custo
  → apply + restore            # continua o estudo sem refazer alertas
```

## Documentos

| Ficheiro | Conteúdo |
|----------|----------|
| [zabbix/PASSO-A-PASSO.md](zabbix/PASSO-A-PASSO.md) | **Guia único ponta a ponta** |
| [PLAN-ZABBIX.md](PLAN-ZABBIX.md) | Plano de implementação |
| [LAB-ALERTAS.md](LAB-ALERTAS.md) | Índice alertas / runbooks |
| [ARQUITETURA.md](ARQUITETURA.md) | Arquitetura |
| [zabbix/00-PRIMEIRO-ACESSO-WIZARD.md](zabbix/00-PRIMEIRO-ACESSO-WIZARD.md) | Wizard DB |
| [zabbix/01-INSTALAR-AGENT.md](zabbix/01-INSTALAR-AGENT.md) | Agent |
| [zabbix/04-CONFIGURAR-ALERTAS.md](zabbix/04-CONFIGURAR-ALERTAS.md) | Criar alertas |
| [zabbix/05-BACKUP-E-RESTORE.md](zabbix/05-BACKUP-E-RESTORE.md) | Destroy sem perder config |
| [zabbix/03-CENARIOS-VIDA-REAL.md](zabbix/03-CENARIOS-VIDA-REAL.md) | 12 cenários |
| [runbooks/](runbooks/) | Runbooks |
| [drills/](drills/) | Drills start/restore |

## Estado

| Item | Status |
|------|--------|
| VPC + K8s kubeadm + Calico | Feito |
| Zabbix 6.4.0 EC2 + UI | Feito |
| Labs CKA | Feito |
| Agents / alertas / drills / backup | Documentado + scripts |

## Custo

- 3× `t3.small` enquanto o lab corre  
- **Sempre:** backup + `destroy`, ou Stop das EC2 no fim da sessão  
