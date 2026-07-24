# Plano — Fase Zabbix

Última atualização: 2026-07-24  
Branch: `feat/zabbix`  
Princípio: evolução incremental; não recriar o lab do zero.  
Decisão: **Zabbix Server em EC2 dedicada** (não em pod) — monitoração independente do cluster.

---

## Experiência alvo (quando estiver pronto)

```bash
# 1) Credenciais / MFA (como hoje)
source ./scripts/aws-mfa-session.sh

# 2) terraform.tfvars
#    allow_ssh_cidrs, ec2_key_name
#    instance_type = "t3.small"
#    enable_zabbix = true          # NOVO

cd terraform
terraform init && terraform apply

# 3) Esperar bootstrap (K8s + Zabbix)
#    Ficheiro gerado deve incluir URL do Zabbix + IPs

# 4) Abrir no browser (só o teu CIDR)
#    http://<ZABBIX_PUBLIC_IP>/zabbix
#    user: Admin  /  password: zabbix   (lab — mudar no 1.º login)

# 5) Seguir sre/LAB-ALERTAS.md

# 6) Encerrar
terraform destroy
```

Objetivo pedagógico: **criar alertas, provocar falhas, ver eventos, reconhecer, mitigar, fechar, documentar**.

---

## Escopo desta fase (sim / não)

### Sim (MVP Zabbix)

- [x] Flag Terraform `enable_zabbix` (default `true`; `false` = só K8s)
- [x] 3.ª EC2: **Zabbix Server** (`zabbix_instance_type`, default `t3.small`) — resource `aws_instance.zabbix`
- [x] Security Group: UI HTTP :80 só em `allow_ssh_cidrs` (agents usam tráfego self do SG no MVP)
- [ ] Bootstrap Server: Zabbix Server + Frontend + DB (PostgreSQL) — **Passo 3** (hoje: stub)
- [ ] Bootstrap Agent nos nós K8s existentes (control-plane + worker)
- [x] Inventário gerado com URL + SSH do Zabbix (`cluster-lab.generated.txt` + outputs)
- [ ] Hosts no Zabbix: `zabbix-server`, `control-plane`, `worker` (auto-registo ou script pós-boot)
- [ ] Template Linux básico (CPU, memória, disco, load, ping, agent)
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

### Passo 3 — Bootstrap Zabbix Server ← **próximo**

- Substituir stub por `install-zabbix-server.sh`
- Frontend + PostgreSQL; credenciais de lab documentadas

### Passo 4 — Agents nos nós K8s

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
| Versão | Zabbix 7.0 LTS (ou estável do repo no momento da implementação) |
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
| Senha default Admin/zabbix | Documentar troca no 1.º acesso |
| Bootstrap longo | Log em `/var/log/zabbix-bootstrap.log`; script wait |
| user_data K8s em nó Zabbix | EC2 separada `aws_instance.zabbix` ✅ |

---

## Próxima ação concreta

Implementar **Passo 3**: instalação real do Zabbix Server + Frontend + PostgreSQL (substituir o stub).
