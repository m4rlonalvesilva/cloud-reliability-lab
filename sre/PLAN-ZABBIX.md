# Plano — Fase Zabbix

Última atualização: 2026-07-24  
Branch: `feat/zabbix`  
Princípio: evolução incremental; não recriar o lab do zero.

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

- [ ] Flag Terraform `enable_zabbix` (default `true` nesta branch de lab, ou `false` para quem só quer K8s)
- [ ] 3.ª EC2: **Zabbix Server** (`t3.small`, Ubuntu)
- [ ] Security Group: UI (80/443) só em `allow_ssh_cidrs`; agent 10050/10051 só entre nós do lab
- [ ] Bootstrap Server: Zabbix Server + Frontend + DB (PostgreSQL ou MySQL — decidir na implementação; preferência PostgreSQL)
- [ ] Bootstrap Agent nos nós K8s existentes (control-plane + worker)
- [ ] Inventário gerado (`cluster-lab.generated.txt` ou ficheiro SRE) com URL + SSH do Zabbix
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

## Mudança obrigatória no Terraform (bloqueante)

Hoje `aws_instance.app` usa `count` e **todas** as instâncias recebem user_data de Kubernetes.

Para Zabbix Server:

1. Separar recursos por **role**:
   - `aws_instance.k8s` (control-plane + workers) — user_data atual
   - `aws_instance.zabbix` (count = enable_zabbix ? 1 : 0) — user_data Zabbix
2. Manter a mesma VPC/subnet
3. SG: evoluir do “self all” para regras mínimas **ou** manter self-all no MVP e documentar endurecimento depois
4. Outputs: `zabbix_public_ip`, `zabbix_url`
5. Não remover o fluxo CKA (`wait-for-cluster.sh` continua a funcionar)

---

## Ordem de implementação (PRs / commits lógicos)

### Passo 1 — Docs (este conjunto `sre/*.md`) ✅ em curso

Salvar plano e roteiro de aprendizagem.

### Passo 2 — Terraform roles + `enable_zabbix`

- Variáveis, SG (UI + agent), EC2 Zabbix sem instalar ainda (user_data stub ou cloud-init mínimo)
- Outputs + inventário
- Validar: `plan` com `enable_zabbix=true` mostra +1 EC2

### Passo 3 — Bootstrap Zabbix Server

- Script `zabbix/scripts/install-zabbix-server.sh` (ou sob `sre/zabbix/`)
- Embutir no user_data (mesmo padrão CRLF→LF do K8s)
- Frontend acessível; credenciais de lab documentadas

### Passo 4 — Agents nos nós K8s

- Instalar `zabbix-agent2` no fim do bootstrap CP/worker **ou** script pós-apply
- Preferência: no bootstrap K8s, se `enable_zabbix` (via tag/SSM/env no user_data)
- ServerActive → IP privado do Zabbix

### Passo 5 — Inventário de hosts + templates

- Script `wait-for-zabbix.sh` ou extensão do inventário
- Criar hosts/grupos via API Zabbix **ou** guia manual no LAB-ALERTAS (MVP pode ser semi-manual)

### Passo 6 — Labs de alerta + drills

- `sre/LAB-ALERTAS.md` (exercícios)
- `sre/drills/` scripts simulate/restore
- Runbooks: CPU, disco, serviço down

### Passo 7 — README raiz

- Secção “Track SRE / Zabbix” apontando para `sre/`
- TL;DR opcional com `enable_zabbix`

---

## Decisões técnicas (fechadas para o MVP)

| Tema | Decisão |
|------|----------|
| Zabbix Server | EC2 dedicada (não no control-plane) — isola carga e falhas |
| Agents | Nos 2 nós K8s + no próprio Server |
| UI | HTTP :80 no MVP; HTTPS depois se necessário |
| Acesso UI | Mesmos CIDRs que SSH (`allow_ssh_cidrs`) |
| DB | PostgreSQL local na EC2 Zabbix |
| Versão | Zabbix 7.0 LTS (ou estável do repo Ubuntu no momento da implementação) |
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
| user_data K8s em nó Zabbix | Roles separadas (Passo 2) |

---

## Próxima ação concreta

Implementar **Passo 2** (Terraform roles + flag), sem ainda instalar o pacote Zabbix — validar `plan`/`apply` da 3.ª EC2 e outputs da URL.
