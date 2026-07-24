# 03 — Cenários da vida real (catálogo)

Pratica cada cenário com o mesmo fluxo: **Ack → Diagnosticar → Mitigar → Resolver → Validar**.

Pré-requisito: agents verdes ([01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md)) + conceitos ([02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md)).

Como correr drills no host (copia o repo ou faz scp da pasta `sre/drills`):

```bash
# Exemplo a partir do teu PC:
scp -i "$SSH_KEY_PATH" -r sre/drills ubuntu@<IP_PUBLICO_DO_NO>:~/
ssh -i "$SSH_KEY_PATH" ubuntu@<IP> 'bash ~/drills/disk-full.sh start'
```

---

## Catálogo

| # | Cenário real | O que simula | Runbook | Drill |
|---|--------------|--------------|---------|-------|
| 1 | Agent Zabbix fora | Monitoração cega | [zabbix-agent-down](../runbooks/zabbix-agent-down.md) | `agent-down.sh` |
| 2 | CPU alta | Processo runaway / pico | [linux-cpu-high](../runbooks/linux-cpu-high.md) | `cpu-high.sh` |
| 3 | Memória alta | Pressure / risco OOM | [linux-memory-high](../runbooks/linux-memory-high.md) | `memory-high.sh` |
| 4 | Disco cheio | `/` ou `/var` a esgotar | [linux-disk-full](../runbooks/linux-disk-full.md) | `disk-full.sh` |
| 5 | Inodes esgotados | Muitos ficheiros pequenos | [linux-inodes-full](../runbooks/linux-inodes-full.md) | `inodes-full.sh` |
| 6 | Serviço systemd down | App/serviço parado | [linux-service-down](../runbooks/linux-service-down.md) | `service-down.sh` |
| 7 | Porta / health down | Serviço “no ar” mas não escuta | [linux-port-down](../runbooks/linux-port-down.md) | `port-down.sh` |
| 8 | Load average alta | Fila de runnable / saturação | [linux-load-high](../runbooks/linux-load-high.md) | `load-high.sh` |
| 9 | Relógio dessincronizado | NTP/chrony parado | [linux-clock-skew](../runbooks/linux-clock-skew.md) | `clock-skew.sh` |
| 10 | Kubelet parado | Nó K8s NotReady | [k8s-kubelet-down](../runbooks/k8s-kubelet-down.md) | `kubelet-down.sh` |
| 11 | Containerd parado | Runtime down (pods falham) | [k8s-containerd-down](../runbooks/k8s-containerd-down.md) | `containerd-down.sh` |
| 12 | Tempestade de logs | Disco a crescer por logs | [linux-log-storm](../runbooks/linux-log-storm.md) | `log-storm.sh` |

---

## Ordem recomendada (sessões)

### Sessão A — Infra Linux clássica
1 → 2 → 3 → 4 → 6

### Sessão B — Disco e filesystem
4 → 5 → 12

### Sessão C — App / disponibilidade
6 → 7 → 9

### Sessão D — Kubernetes (nós do lab)
10 → 11 (sempre com `restore` antes de sair)

---

## Regra de ouro do lab

- Cada `start` tem um `restore` — **corre o restore** antes de `terraform destroy` ou de ir embora.
- Não uses drills destrutivos na root sem teto (os scripts limitam tamanho / path em `/var/tmp`).
- Em K8s (10–11), o cluster fica degradado de propósito; restaura e valida `kubectl get nodes`.

---

## Severidade (lembrança SRE)

| Cenário | Severidade típica | Porquê |
|---------|-------------------|--------|
| CPU / load / mem (sem impacto app) | WARNING | Sinal; correlacionar com SLO |
| Disco / inodes / serviço / porta | HIGH | Impacto operacional claro |
| Agent down | HIGH | Perda de visibilidade |
| Kubelet / containerd down | HIGH/CRITICAL | Workloads afetados |
| Clock skew | WARNING→HIGH | Certs, logs, Kerberos, TLS |

Índice Zabbix: [README.md](README.md)
