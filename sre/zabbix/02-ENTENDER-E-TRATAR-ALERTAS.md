# 02 — Entender alertas e corrigir como na vida real

**Quando usar:** agents verdes ([01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md)).

**Objetivo:** perceber *como* um alerta nasce no Zabbix e *o que fazer* quando aparece — no lab, com a mesma lógica de produção.

---

## Como um alerta funciona (modelo mental)

```text
Máquina (Linux)
   │  agent recolhe métricas / estado
   ▼
Item (métrica)          ex.: CPU util %, memória disponível, agent.ping
   │
   ▼
Trigger (regra)         ex.: CPU > 90% durante 5 min
   │  condição VERDADEIRA?
   ▼
Problem (alerta ativo)  aparece em Monitoring → Problems
   │
   ▼
Tu (operador)           Acknowledge → Diagnosticar → Mitigar → Resolver → Validar
```

| Peça | O que é | Onde vês na UI |
|------|---------|----------------|
| **Item** | Dado medido | Latest data / Data collection → Items |
| **Trigger** | “Se X durante Y → problema” | Data collection → Triggers |
| **Problem** | Trigger a disparar *agora* | Monitoring → Problems |
| **Acknowledge** | “Estou a tratar” + nota | no Problem → Acknowledge |
| **OK / Resolved** | Condição voltou ao normal | Problem fecha sozinho (na maioria dos casos) |

**Importante:** o template Linux já traz triggers. Com a máquina saudável, **Problems pode estar vazio** — os triggers existem, mas estão OK. Só vês alerta quando a condição se cumpre.

---

## Fluxo de tratamento (igual na vida real)

Usa sempre esta ordem no lab:

1. **Ver o sintoma** — Problems / dashboard  
2. **Acknowledge** — “Investigando — lab” (em prod: ticket/incidente)  
3. **Classificar impacto** — só ruído? serviço afetado? monitoração cega?  
4. **Diagnosticar causa** — comandos no host (não só olhar o gráfico)  
5. **Mitigar** — parar o sangramento (matar processo, restart serviço, libertar RAM…)  
6. **Resolver causa** — se for drill, restaurar; se for real, corrigir root cause  
7. **Validar** — Latest data + Problem em OK + serviço a responder  

Runbooks detalhados:

| Cenário | Runbook |
|---------|---------|
| Agent Zabbix fora / unreachable | [../runbooks/zabbix-agent-down.md](../runbooks/zabbix-agent-down.md) |
| CPU alta | [../runbooks/linux-cpu-high.md](../runbooks/linux-cpu-high.md) |
| Memória alta | [../runbooks/linux-memory-high.md](../runbooks/linux-memory-high.md) |

---

## Lab 1 — Agent Zabbix fora

### O que o alerta significa

O Server **deixou de conseguir falar** com o agent (passive) e/ou o agent **deixou de reportar** (active).  
Estás “cego” para aquela máquina: CPU/memória/disco deixam de atualizar com confiança.

Severidade típica na vida real: **HIGH** (perda de monitoração daquele host).

### Como provocar (lab)

No **worker** (SSH):

```bash
sudo systemctl stop zabbix-agent2
sudo systemctl status zabbix-agent2 --no-pager
```

Espera 1–3 minutos → **Monitoring → Problems** (e/ou host a vermelho).

### O que fazer (como em produção)

Segue o runbook: [zabbix-agent-down.md](../runbooks/zabbix-agent-down.md)

Resumo:

```bash
# Ainda tens SSH? (em prod muitas vezes sim, mesmo sem agent)
sudo systemctl status zabbix-agent2
sudo journalctl -u zabbix-agent2 -n 50 --no-pager
sudo systemctl start zabbix-agent2
sudo systemctl enable zabbix-agent2
```

Validar: agent verde + `agent.ping` / Latest data a atualizar + Problem OK.

---

## Lab 2 — CPU alta

### O que o alerta significa

A utilização de CPU passou o limiar do trigger (ex. >90% durante N minutos).  
**Sozinha não diz** se a app está a falhar — em SRE, CPU alta = WARNING até haver impacto (latência, erros).

### Como provocar (lab)

No worker:

```bash
# stress com yes (Ctrl+C para parar, ou usa o drill com timeout)
# 2 processos a consumir CPU ~2 minutos
timeout 120 bash -c 'yes > /dev/null & yes > /dev/null & wait' 
# ou:
./sre/drills/cpu-high.sh    # se estiveres na máquina com o repo; senão usa o bloco abaixo
```

Sem o script no servidor, no SSH:

```bash
# CPU alta ~3 min, depois pára sozinho
timeout 180s bash -c 'for i in 1 2; do yes >/dev/null & done; wait' &
```

Melhor (controlado): copia/cola o drill do repo ou corre a partir do PC via SSH — ver [cpu-high runbook](../runbooks/linux-cpu-high.md).

### O que fazer (como em produção)

1. Acknowledge no Zabbix  
2. No host: `top` / `htop` / `ps` — **quem** está a consumir?  
3. Mitigar: parar processo ilegítimo, limitar, restart do serviço culpado  
4. No lab: parar o `yes` / drill  
5. Validar: CPU desce no Latest data; Problem OK  

Detalhe: [linux-cpu-high.md](../runbooks/linux-cpu-high.md)

---

## Lab 3 — Memória alta

### O que o alerta significa

Memória disponível baixa / utilização alta. Risco: swap thrashing, OOM Killer, pods/processos mortos.

### Como provocar (lab)

Com cuidado (não encher até a máquina ficar inacessível):

```bash
# Consome ~512MB por ~2 min (ajusta se a VM for pequena)
timeout 120s head -c 512M /dev/zero | tail >/dev/null &
```

Ou o drill: ver [linux-memory-high.md](../runbooks/linux-memory-high.md).

### O que fazer (como em produção)

1. Acknowledge  
2. `free -h`, `ps aux --sort=-%mem | head`, `dmesg | grep -i oom`  
3. Mitigar: reiniciar processo com leak, libertar cache só se souberes o que fazes, escalar verticalmente (prod)  
4. Lab: matar o processo do drill  
5. Validar: memória recupera; Problem OK  

---

## Tabela rápida: alerta → ação

| Alerta | Significa | Primeira ação | “Corrigir” no lab |
|--------|-----------|---------------|-------------------|
| Agent down / unavailable | Sem monitoração do host | SSH + `systemctl status/start zabbix-agent2` | `systemctl start zabbix-agent2` |
| CPU high | CPU no limiar | `top` — quem consome? | Parar stress/`yes` |
| Memory high / low available | RAM no limiar | `free -h` + top por `%mem` | Parar processo de stress |
| (mais tarde) Disco cheio | Filesystem no limiar | `df -h` + limpar / logs | Apagar ficheiro de drill |

---

## Ordem sugerida de prática (1 sessão)

1. Confirma hosts verdes  
2. Lab 1 agent down → trata → valida  
3. Lab 2 CPU → trata → valida  
4. Lab 3 memória → trata → valida  
5. Anota 3 linhas por incidente: sintoma / causa / o que fizeste  

Depois aprofunda em [../LAB-ALERTAS.md](../LAB-ALERTAS.md) (criar triggers teus, severidades, anti-padrões).

---

## Drills (reproduzir / restaurar)

| Drill | Ficheiro |
|-------|----------|
| CPU alta | [`../drills/cpu-high.sh`](../drills/cpu-high.sh) |
| Memória alta | [`../drills/memory-high.sh`](../drills/memory-high.sh) |
| Agent parado | [`../drills/agent-down.sh`](../drills/agent-down.sh) |

Cada script aceita `start` e `restore` e imprime o que está a fazer.
