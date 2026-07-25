# Plano — Fase Zabbix

Última atualização: 2026-07-24  
Branch: `feat/zabbix`  
Princípio: evolução incremental; não recriar o lab do zero.  
Decisão: **Zabbix Server em EC2 dedicada** (não em pod) — monitoração independente do cluster.

---

## Experiência alvo

Passo a passo atualizado: **[`zabbix/PASSO-A-PASSO.md`](zabbix/PASSO-A-PASSO.md)**

```bash
# 1) MFA + tfvars (allow_ssh_cidrs = teu IP atual, enable_zabbix = true, t3.small)
source ./scripts/aws-mfa-session.sh
cd terraform && terraform apply && cd ..

# 2) Esperar Zabbix 6.4.0
export SSH_KEY_PATH="/c/Users/.../sua-chave.pem"
./sre/zabbix/scripts/wait-for-zabbix.sh
# wizard se pedir: DB LabZabbixDB, TLS off → sre/zabbix/00-PRIMEIRO-ACESSO-WIZARD.md

# 3) Agents + hosts (1.ª vez) ou restore (retomar)
./sre/zabbix/scripts/install-agents-remote.sh
# 1.ª vez: criar hosts na UI (01-INSTALAR-AGENT.md)
# retomar: restore + sync IPs (05-BACKUP-E-RESTORE.md)

# 4) Alertas / drills
# sre/zabbix/04-CONFIGURAR-ALERTAS.md  +  03-CENARIOS-VIDA-REAL.md

# 5) Fim de sessão — NÃO perder alertas
export ZABBIX_PASSWORD=zabbix
./sre/zabbix/scripts/backup-zabbix-config.sh
git add sre/zabbix/config-export && git commit -m "chore: backup config Zabbix"
cd terraform && terraform destroy
```

Objetivo pedagógico: **criar alertas, provocar falhas, tratar como em produção, destruir infra sem perder a config de estudo**.

---

## Escopo desta fase (sim / não)

### Sim (MVP Zabbix)

- [x] Flag Terraform `enable_zabbix` (default `true`; `false` = só K8s)
- [x] 3.ª EC2: **Zabbix Server** (`zabbix_instance_type`, default `t3.small`) — resource `aws_instance.zabbix`
- [x] Security Group: UI HTTP :80 só em `allow_ssh_cidrs` (agents usam tráfego self do SG no MVP)
- [x] Bootstrap Server: Zabbix **6.4.0** + Frontend Apache + PostgreSQL (`install-zabbix-server.sh`)
- [ ] Bootstrap Agent nos nós K8s existentes (control-plane + worker)
- [x] Inventário gerado com URL + SSH do Zabbix (`cluster-lab.generated.txt` + outputs)
- [ ] Hosts no Zabbix: `control-plane`, `worker` (além do “Zabbix server” local)
- [ ] Template Linux básico nos hosts K8s (agent)
- [ ] Documentação: LAB-ALERTAS + 2–3 runbooks Linux iniciais
- [ ] Scripts seguros de simulação: CPU alta, disco cheio, serviço parado (+ restore)

### Não nesta fase

- Kafka, WebLogic, Oracle, app `/orders`
- Auto-remediation avançada
- Stack Prometheus/Grafana
- EC2 dedicada Kafka/WebLogic
- Alertas compostos multi-camada (fica para depois; no MVP: 1 exemplo simples severidade)

---

## Mudança obrigatória no Terraform (bloqueante) — ✅ Passo 2

K8s permanece em `aws_instance.app` (evita recreate). Zabbix em `aws_instance.zabbix` (`enable_zabbix`).

Outputs: `zabbix_public_ip`, `zabbix_private_ip`, `zabbix_url`. Fluxo CKA intacto.

---

## Ordem de implementação (PRs / commits lógicos)

### Passo 1 — Docs (`sre/*.md`) ✅

### Passo 2 — Terraform + `enable_zabbix` ✅

- `terraform/zabbix.tf`, stub `sre/zabbix/scripts/bootstrap-stub.sh`
- SG :80, inventário, outputs

### Passo 3 — Bootstrap Zabbix Server ✅

- `sre/zabbix/scripts/install-zabbix-server.sh`
- `sre/zabbix/scripts/wait-for-zabbix.sh`
- `sre/zabbix/ACCESS.md` (Admin/zabbix)

### Passo 4 — Agents nos nós K8s ← **próximo**

- `zabbix-agent2` no bootstrap CP/worker; ServerActive → IP privado do Zabbix

### Passo 5 — Inventário de hosts + templates

### Passo 6 — Labs de alerta + drills

### Passo 7 — README raiz (TL;DR Zabbix)

---

## Decisões técnicas (fechadas para o MVP)

| Tema | Decisão |
|------|----------|
| Zabbix Server | **EC2 dedicada** (não pod) — monitoração independente do cluster |
| Agents | Nos 2 nós K8s + no próprio Server |
| UI | HTTP :80 no MVP; HTTPS depois se necessário |
| Acesso UI | Mesmos CIDRs que SSH (`allow_ssh_cidrs`) |
| DB | PostgreSQL local na EC2 Zabbix |
| Versão | Zabbix **6.4.0** (repo oficial 6.4, Ubuntu 22.04, pacotes pinados) |
| Kafka/WebLogic | Fora do MVP |
| CKA labs | Continuam; `CKA_DEPLOY_LABS=false` se quiseres só SRE numa sessão |

---

## Critérios de “lab pronto”

1. `terraform apply` conclui sem erro com `enable_zabbix=true`
2. Browser abre UI Zabbix a partir do teu IP
3. Três hosts com agent disponível (verde)
4. Consegues criar um trigger, disparar um drill, ver problema, reconhecer, restaurar, fechar
5. `terraform destroy` remove tudo (incluindo EC2 Zabbix e SG)

---

## Riscos e mitigações

| Risco | Mitigação |
|-------|-----------|
| Custo 3× EC2 | `enable_zabbix=false`; destroy ao fim; Budget AWS |
| UI aberta na internet | Só `allow_ssh_cidrs`; nunca `0.0.0.0/0` |
| Senha default Admin/zabbix | Documentar troca no 1.º acesso (`ACCESS.md`) |
| Bootstrap longo | Log + `wait-for-zabbix.sh` |
| user_data K8s em nó Zabbix | EC2 separada `aws_instance.zabbix` ✅ |

---

## Próxima ação concreta

Implementar **Passo 4**: `zabbix-agent2` nos nós K8s apontando para o IP privado do Zabbix Server.
