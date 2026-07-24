# Lab — Criar e tratar alertas no Zabbix

Começa por entender e praticar os 3 cenários mais comuns:

→ **[`zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md`](zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md)**  
(agent fora · CPU alta · memória alta — com runbooks e drills)

---

## Pré-requisitos

- [ ] `terraform apply` com Zabbix ligado
- [ ] UI a responder (`./sre/zabbix/scripts/wait-for-zabbix.sh`)
- [ ] Login **Admin** / **zabbix**
- [ ] Agents instalados — [`zabbix/01-INSTALAR-AGENT.md`](zabbix/01-INSTALAR-AGENT.md)
- [ ] Hosts com agent Available (verde)

---

## Conceitos (mapa rápido)

| Conceito | O que é |
|----------|---------|
| Host | Máquina/serviço monitorado |
| Item | Métrica ou check (ex.: CPU idle) |
| Trigger | Condição que gera problema (ex.: CPU > 90% por 5 min) |
| Problem | Instância ativa de um trigger |
| Acknowledge | Registo de que alguém está a tratar |

Os templates já trazem triggers. **Problems vazio com host saudável é normal.**

---

## Runbooks (tratar como em produção)

| Cenário | Runbook | Drill |
|---------|---------|-------|
| Agent fora | [runbooks/zabbix-agent-down.md](runbooks/zabbix-agent-down.md) | `drills/agent-down.sh` |
| CPU alta | [runbooks/linux-cpu-high.md](runbooks/linux-cpu-high.md) | `drills/cpu-high.sh` |
| Memória alta | [runbooks/linux-memory-high.md](runbooks/linux-memory-high.md) | `drills/memory-high.sh` |

Fluxo: **Ack → Diagnosticar → Mitigar → Resolver → Validar**.

---

## Exercícios extra (depois dos 3 labs)

### Criar o teu trigger de CPU

1. Template ou trigger custom no worker  
2. Severidade **Warning** (CPU sozinha ≠ P1)  
3. Disparar com `drills/cpu-high.sh start` → tratar → `restore`

### Política de severidade

| Severidade | Significado | Exemplo |
|------------|-------------|---------|
| WARNING | Degradado, serviço no ar | CPU alta sem erros de app |
| HIGH | Agir agora | Agent down, disco > 90% |
| CRITICAL | Indisponível / cego total | Host down, Zabbix Server down |

### Anti-padrões

- CPU > 70% = Disaster  
- Dezenas de alerts sem tratar o agent down primeiro  
- Alertas sem acknowledge  

---

## Checklist pós-sessão

- [ ] Drills com `restore` feitos  
- [ ] Password Admin alterada  
- [ ] `terraform destroy` se não fores continuar  
