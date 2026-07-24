# Lab — Criar e tratar alertas no Zabbix

Roteiro de aprendizagem **depois** do lab estar no ar (`terraform apply` + Zabbix acessível).

Este ficheiro descreve o **que vais praticar**. Os passos exatos de UI serão refinados quando o bootstrap estiver implementado.

---

## Pré-requisitos

- [ ] `terraform apply` com Zabbix ligado
- [ ] UI a responder (`./sre/zabbix/scripts/wait-for-zabbix.sh`)
- [ ] Login **Admin** / **zabbix**
- [ ] Agents instalados nos nós — segue **[`zabbix/01-INSTALAR-AGENT.md`](zabbix/01-INSTALAR-AGENT.md)**
- [ ] Hosts `control-plane` e `worker` com agent Available (verde)
---

## Conceitos (mapa rápido)

| Conceito | O que é |
|----------|---------|
| Host | Máquina/serviço monitorado |
| Item | Métrica ou check (ex.: CPU idle) |
| Trigger | Condição que gera problema (ex.: CPU > 90% por 5 min) |
| Problem | Instância ativa de um trigger |
| Severity | Informação → Aviso → Médio → Alto → Desastre (mapear para INFO/WARNING/HIGH/CRITICAL no lab) |
| Action | O que fazer ao disparar (e-mail, webhook, script — no MVP: só UI + acknowledge) |
| Acknowledge | Registo de que alguém está a tratar |
| Dependency | Evitar avalanche (ex.: se host down, não alertar cada item) |

---

## Exercício 0 — Orientação (15 min)

1. Abrir **Monitoring → Hosts** e confirmar agents verdes.
2. Abrir **Latest data** de um host (CPU, memória, disco).
3. Abrir **Monitoring → Problems** (deve estar vazio ou quase).
4. Anotar: o que é “ruído” vs “sinal” neste lab.

---

## Exercício 1 — Criar o primeiro alerta (30 min)

Objetivo: trigger de **CPU alta** no `worker` (ou control-plane).

1. Usar template Linux já ligado **ou** criar trigger simples sobre item de CPU.
2. Severidade: **Warning** (não Critical — CPU alta sozinha não é P1).
3. Nome claro, ex.: `CPU utilization > 90% on {HOST.NAME}`.
4. Documentar em 3 linhas: o que significa / impacto / quando escalar.

**Critério de sucesso:** trigger existe e está OK (não em problema) com carga normal.

---

## Exercício 2 — Disparar e tratar (45 min)

1. Correr drill de CPU (quando existir: `sre/drills/cpu-high.sh` + `restore`).
2. Ver o Problem aparecer (refresh / dashboard).
3. **Acknowledge** com mensagem: “Investigando — drill de lab”.
4. Confirmar Latest data / gráficos.
5. Restaurar o drill.
6. Esperar resolução (OK) e fechar o ciclo.

**Critério de sucesso:** timeline Detection → Ack → Resolve compreensível.

---

## Exercício 3 — Serviço parado (45 min)

1. Trigger: serviço systemd crítico parado (ex.: `zabbix-agent2` num worker **ou** um serviço de lab dedicado).
2. Severidade: **High** (serviço parado = impacto operacional claro).
3. Drill: `systemctl stop …` / restore `start`.
4. Praticar: diagnóstico → mitigação → validação.

---

## Exercício 4 — Disco cheio (45 min)

1. Trigger: filesystem > 90%.
2. Drill controlado (ficheiro grande em `/var/tmp/lab-fill` — **nunca** encher partição root sem restore documentado).
3. Severidade: **High** ou **Disaster** conforme % e partição.
4. Runbook mental: limpar ficheiro de drill, validar espaço, confirmar Problem OK.

---

## Exercício 5 — Política de severidade (30 min)

Definir e colar no teu caderno / futuro runbook:

| Severidade lab | Significado | Exemplo |
|----------------|-------------|---------|
| INFO | Sinal informativo, sem ação urgente | Inventário / discovery |
| WARNING | Atenção; degradado mas serviço no ar | CPU > 90% sem erro de app |
| HIGH | Impacto operacional; agir agora | Serviço down, disco > 90% |
| CRITICAL | Lab “indisponível” / perda de monitoração | Zabbix Server unreachable, host down |

Regra de ouro do track SRE: **métrica de infra sozinha raramente é CRITICAL** — CRITICAL exige impacto (serviço/host indisponível).

---

## Exercício 6 — Anti-padrões (15 min)

Discutir / anotar por que **não** fazer:

- CPU > 70% = Disaster
- 50 triggers sem dependency quando o host cai
- Alertas sem dono / sem acknowledge
- Senha default na UI exposta

---

## Checklist pós-sessão

- [ ] Password Admin alterada
- [ ] Drills restaurados
- [ ] `terraform destroy` se não fores continuar
- [ ] Notas do que foi difícil (alimentar runbooks depois)

---

## Runbooks (a criar com os drills)

| Ficheiro (previsto) | Exercício |
|---------------------|-----------|
| `sre/runbooks/linux-cpu-high.md` | 1–2 |
| `sre/runbooks/linux-service-down.md` | 3 |
| `sre/runbooks/linux-disk-full.md` | 4 |

Cada runbook: Sintoma → Impacto → Diagnóstico → Comandos → Mitigação → Resolução → Validação.
