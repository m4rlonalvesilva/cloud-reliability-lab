# 05 — Destroy com custo baixo e retomar o estudo (backup/restore)

Queres **`terraform destroy`** para não pagar, mas **não** queres refazer wizard + hosts + alertas do zero.

## O que o Terraform já recria sozinho

| Componente | Após novo `apply` |
|------------|-------------------|
| VPC, EC2, SG | Sim |
| Zabbix Server 6.4.0 + UI | Sim (bootstrap) |
| Cluster K8s | Sim |

## O que se perde no destroy (e nós guardamos no Git)

| Componente | Solução |
|------------|---------|
| Hosts, grupos, triggers LAB, templates custom | **Backup API → `config-export/`** |
| IPs dos agents (mudam em cada apply) | Script **sync IPs** após restore |
| Agent instalado nos nós | Script **install-agents-remote** |

Histórico de métricas (gráficos antigos) **não** é o foco do lab — perde-se no destroy. A **configuração** de alertas é o que importa para estudar.

---

## Fluxo oficial (usa sempre)

### A) Antes de destruir (fim da sessão de estudo)

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
export ZABBIX_URL="$(cd terraform && terraform output -raw zabbix_url)"
export ZABBIX_USER=Admin
export ZABBIX_PASSWORD=zabbix   # ou a password que definiste

# 1) Exporta hosts + templates (+ triggers associados) para o repo
./sre/zabbix/scripts/backup-zabbix-config.sh

# 2) Commit (estado do lab versionado)
git add sre/zabbix/config-export/
git commit -m "chore: backup config Zabbix do lab"
# git push   # opcional

# 3) Destruir infra (para o custo)
cd terraform && terraform destroy
```

### B) Quando fores continuar a estudar

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"

# 0) IP público atualizado em terraform.tfvars (allow_ssh_cidrs)
./scripts/get-my-public-ip.sh

cd terraform && terraform apply

# 1) Esperar Zabbix
cd ..
./sre/zabbix/scripts/wait-for-zabbix.sh

# 2) Se aparecer o wizard → sre/zabbix/00-PRIMEIRO-ACESSO-WIZARD.md
#    (password DB: LabZabbixDB, TLS off)

export ZABBIX_URL="$(cd terraform && terraform output -raw zabbix_url)"
export ZABBIX_USER=Admin
export ZABBIX_PASSWORD=zabbix

# 3) Agents nos nós (automático via SSH)
./sre/zabbix/scripts/install-agents-remote.sh

# 4) Restaurar hosts/triggers do Git
./sre/zabbix/scripts/restore-zabbix-config.sh

# 5) Atualizar IPs das interfaces Agent (mudaram no novo apply)
./sre/zabbix/scripts/sync-host-agent-ips.sh
```

Pronto: UI com os teus alertas LAB de novo, sem os ter configurado outra vez.

---

## Onde ficam os ficheiros

```text
sre/zabbix/config-export/
  hosts.json       # hosts + triggers de host
  templates.json   # templates custom (se existirem)
  README.md
```

Estes ficheiros **devem ir para o Git** (não têm secrets da AWS; a password Admin não vai no export).

---

## Alternativa ainda mais barata (pausa curta)

Se fores voltar em **horas/1–2 dias**, em vez de destroy:

- **Stop** das 3 EC2 na consola AWS (disco gp3 continua a custar pouco)
- **Start** depois — o Zabbix e a config mantêm-se
- O IP **público** pode mudar → atualiza URL e, se precisares, `allow_ssh_cidrs`

Para pausas longas (semanas): **destroy + backup** (fluxo A/B).

---

## Checklist mental

| Situação | Ação |
|----------|------|
| Fim do dia, continuo amanhã | Stop EC2 **ou** backup + destroy |
| Fim da semana / férias | **backup + commit + destroy** |
| Novo apply | wait → agents → restore → sync IPs |
| IP do PC mudou | atualizar `allow_ssh_cidrs` + apply |

---

## Scripts

| Script | Função |
|--------|--------|
| [backup-zabbix-config.sh](scripts/backup-zabbix-config.sh) | Export API → `config-export/` |
| [restore-zabbix-config.sh](scripts/restore-zabbix-config.sh) | Import API a partir do Git |
| [install-agents-remote.sh](scripts/install-agents-remote.sh) | Instala agent2 nos nós K8s |
| [sync-host-agent-ips.sh](scripts/sync-host-agent-ips.sh) | Corrige IPs após novo apply |
| [wait-for-zabbix.sh](scripts/wait-for-zabbix.sh) | Espera UI pronta |

Depois de restaurar, continua em [04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md) ou [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md).
