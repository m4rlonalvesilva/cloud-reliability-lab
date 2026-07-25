# Passo a passo — Lab Zabbix SRE (completo)

Guia único do início ao fim. Versão do Server: **Zabbix 6.4.0**.

```text
apply → wait → wizard (se precisar) → agents → hosts → alertas → drills
                                                      ↓
                              fim da sessão: backup → commit → destroy
                              próxima sessão: apply → restore (sem refazer alertas)
```

---

## 0) Preparação (PC)

```bash
cd cloud-reliability-lab
source ./scripts/aws-mfa-session.sh   # se a conta exigir MFA

# IP público atual (SSH + UI Zabbix)
./scripts/get-my-public-ip.sh
```

Edita `terraform/terraform.tfvars`:

```hcl
aws_region                  = "us-east-1"
allow_ssh_cidrs             = ["SEU.IP.PUBLICO/32"]   # output do script acima
ec2_key_name                = "cloud-reliability-lab-key"
instance_type               = "t3.small"
expose_kubernetes_api_https = true
enable_zabbix               = true
zabbix_instance_type        = "t3.small"
```

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/cloud-reliability-lab-key.pem"
```

---

## 1) Subir a infra

```bash
cd terraform
terraform init
terraform plan
terraform apply
cd ..
```

Sobe: 2× EC2 K8s + 1× EC2 Zabbix (Server 6.4.0).

---

## 2) Esperar o Zabbix

```bash
./sre/zabbix/scripts/wait-for-zabbix.sh
cd terraform && terraform output zabbix_url && cd ..
```

Abre a URL no browser (só o teu CIDR).

---

## 3) Primeiro acesso (wizard) — só se aparecer

Se vires **Configure DB connection**, segue [00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md).

| Campo | Valor |
|-------|--------|
| Database type | PostgreSQL |
| Database host | `localhost` |
| Database port | `0` |
| Database name | `zabbix` |
| User | `zabbix` |
| Password | `LabZabbixDB` |
| Database TLS encryption | **desmarcar** |

Login UI:

| Campo | Valor |
|-------|--------|
| Username | `Admin` |
| Password | `zabbix` |

Altera a password do Admin no 1.º login.

---

## 4) Instalar agents nos nós

### Opção A — Automática (recomendado)

```bash
./sre/zabbix/scripts/install-agents-remote.sh
```

### Opção B — Manual (aprender)

Segue [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) (SSH + apt + conf).

---

## 5) Hosts na UI (1.ª vez neste lab)

Se **ainda não** tens backup em `config-export/`:

1. **Data collection → Hosts → Create host**
2. Cria `control-plane` e `worker` com:
   - Interface Agent = IP **privado** do nó (`hostname -I` no SSH)
   - Porta `10050`
   - Template: `Linux by Zabbix agent`
   - **Host name** = igual ao `Hostname=` do agent (`control-plane` / `worker`)

Detalhe: [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) blocos 4–5.

Validar: **Monitoring → Hosts** → agent **verde** + **Latest data**.

### Se estás a retomar após destroy

```bash
export ZABBIX_PASSWORD=zabbix   # ou a password nova do Admin
./sre/zabbix/scripts/restore-zabbix-config.sh
./sre/zabbix/scripts/sync-host-agent-ips.sh
```

---

## 6) Configurar e aprender alertas

1. Conceitos: [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md)  
2. Criar triggers na UI: [04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md)  
3. Cenários reais (CPU, disco, agent, kubelet, …): [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md)  

Fluxo de tratamento: **Ack → Diagnosticar → Mitigar → Resolver → Validar**  
Drills: `sre/drills/*.sh` (`start` / `restore`).

---

## 7) Fim da sessão (controlo de custo)

### 7a) Guardar o estado dos alertas (obrigatório antes do destroy)

```bash
export ZABBIX_PASSWORD=zabbix
./sre/zabbix/scripts/backup-zabbix-config.sh
git add sre/zabbix/config-export/
git status
git commit -m "chore: backup config Zabbix do lab"
# git push   # recomendado
```

### 7b) Destruir a infra

```bash
cd terraform && terraform destroy
```

Guia completo: [05-BACKUP-E-RESTORE.md](05-BACKUP-E-RESTORE.md).

**Pausa curta (horas):** podes só **Stop** das 3 EC2 na AWS em vez de destroy.

---

## 8) Continuar noutro dia (após destroy)

```bash
# IP pode ter mudado
./scripts/get-my-public-ip.sh
# atualiza allow_ssh_cidrs em terraform.tfvars se necessário

cd terraform && terraform apply && cd ..
export SSH_KEY_PATH="..."
./sre/zabbix/scripts/wait-for-zabbix.sh
# wizard só se pedir

export ZABBIX_PASSWORD=zabbix
./sre/zabbix/scripts/install-agents-remote.sh
./sre/zabbix/scripts/restore-zabbix-config.sh
./sre/zabbix/scripts/sync-host-agent-ips.sh
```

Não precisas recriar os triggers à mão — vêm do `config-export/` no Git.

---

## Checklist rápido

### 1.ª sessão
- [ ] `terraform apply`
- [ ] UI + login Admin
- [ ] Agents + hosts verdes
- [ ] Pelo menos 1 trigger LAB criado / 1 drill praticado
- [ ] **backup** + commit
- [ ] `terraform destroy` (ou Stop)

### Sessões seguintes
- [ ] `apply` + wait
- [ ] agents remote
- [ ] restore + sync IPs
- [ ] continuar drills / alertas
- [ ] backup outra vez antes do destroy

---

## Mapa dos documentos

| Doc | Quando |
|-----|--------|
| [00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md) | Ecrã Configure DB |
| [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) | Agent manual + hosts UI |
| [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md) | Como alertas funcionam |
| [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md) | 12 cenários |
| [04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md) | Criar triggers |
| [05-BACKUP-E-RESTORE.md](05-BACKUP-E-RESTORE.md) | Destroy sem perder config |
| [ACCESS.md](ACCESS.md) | URL, logs, troubleshooting |
| [../LAB-ALERTAS.md](../LAB-ALERTAS.md) | Índice de alertas/runbooks |
