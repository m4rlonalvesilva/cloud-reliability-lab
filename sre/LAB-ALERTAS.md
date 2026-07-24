# Lab — Criar e tratar alertas no Zabbix

## Começa aqui

1. Agents: [`zabbix/01-INSTALAR-AGENT.md`](zabbix/01-INSTALAR-AGENT.md)  
2. Como alertas funcionam: [`zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md`](zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md)  
3. **Cenários vida real:** [`zabbix/03-CENARIOS-VIDA-REAL.md`](zabbix/03-CENARIOS-VIDA-REAL.md)  

---

## Pré-requisitos

- [ ] Zabbix UI (`Admin` / `zabbix`)  
- [ ] Agents verdes no control-plane e worker  

---

## Catálogo rápido

| Cenário | Runbook |
|---------|---------|
| Agent fora | [runbooks/zabbix-agent-down.md](runbooks/zabbix-agent-down.md) |
| CPU / mem / load | [cpu](runbooks/linux-cpu-high.md) · [mem](runbooks/linux-memory-high.md) · [load](runbooks/linux-load-high.md) |
| Disco / inodes / logs | [disk](runbooks/linux-disk-full.md) · [inodes](runbooks/linux-inodes-full.md) · [logs](runbooks/linux-log-storm.md) |
| Serviço / porta | [service](runbooks/linux-service-down.md) · [port](runbooks/linux-port-down.md) |
| Relógio | [clock](runbooks/linux-clock-skew.md) |
| K8s kubelet / containerd | [kubelet](runbooks/k8s-kubelet-down.md) · [containerd](runbooks/k8s-containerd-down.md) |

Drills: [`drills/README.md`](drills/README.md) — sempre `restore` no fim.

Fluxo: **Ack → Diagnosticar → Mitigar → Resolver → Validar**.

---

## Severidade (SRE)

| Nível | Quando |
|-------|--------|
| WARNING | CPU/mem/load sem impacto claro de app |
| HIGH | Disco, serviço, agent, porta, nó degradado |
| CRITICAL | Indisponibilidade ampla / cluster partido |

---

## Checklist pós-sessão

- [ ] Todos os drills com `restore`  
- [ ] Nodes Ready (`kubectl get nodes`)  
- [ ] `terraform destroy` se não continuares  
