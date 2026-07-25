# 04 — Configurar alertas (aprender na UI)

**Objetivo:** criar e perceber triggers no Zabbix 6.4 — não só esperar pelos do template.

**Pré-requisitos**

- [ ] Wizard / login ok ([00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md))  
- [ ] Agents verdes ([01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md))  
- [ ] Hosts `control-plane` e/ou `worker` com template Linux  

---

## Conceito rápido

| Peça | Função |
|------|--------|
| Item | Métrica (ex. CPU %) |
| Trigger | Regra: “se métrica X durante Y → problema” |
| Problem | Alerta ativo em **Monitoring → Problems** |
| Action | (depois) e-mail/script — no lab começa só com Problems + Acknowledge |

Fluxo de tratamento: [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md)

---

## Exercício A — Ver triggers que já existem (10 min)

1. **Data collection → Hosts** → abre o host `worker`  
2. Separador **Triggers** (ou **Data collection → Triggers**, filtra pelo host)  
3. Anota 3 nomes (ex. CPU, memória, agent unavailable)  
4. **Monitoring → Problems** — com host saudável pode estar **vazio** (normal)

---

## Exercício B — Criar trigger de CPU alta (20 min)

### B1. Encontrar o item de CPU

1. **Data collection → Hosts** → `worker` → **Items**  
2. Procura algo como `CPU utilization` / `system.cpu.util`  
3. Copia o **nome** do item (vais ligar o trigger a ele)

### B2. Criar o trigger

1. **Data collection → Hosts** → `worker` → **Triggers** → **Create trigger**  
2. Preenche:

| Campo | Valor sugerido (lab) |
|-------|----------------------|
| **Name** | `LAB: CPU utilization > 90% on {HOST.NAME}` |
| **Severity** | Warning (não Disaster) |
| **Expression** | ver abaixo |

**Expression (Zabbix 6.4 — UI ajuda a montar):**

Usa o botão **Add** na expressão e escolhe o item de CPU, por exemplo:

```text
last(/worker/system.cpu.util[,user])>90
```

> O nome exato da key depende do template. Preferível: no formulário do trigger, **Add** → selecionar o item → condição `last()` `>` `90`.

Se quiseres “durante 2 minutos” (menos ruído):

```text
min(/worker/system.cpu.util[,user],2m)>90
```

(ajusta a key ao teu item real)

3. **Description** (boa prática SRE):

```text
CPU alta no host. Impacto: possível lentidão.
Investigar com top/ps. Severidade WARNING até haver impacto de app.
```

4. **Add** / **Update**

### B3. Disparar e tratar

No worker (SSH):

```bash
# copia drills se ainda não tiveres
bash ~/drills/cpu-high.sh start
# espera o Problem na UI → Acknowledge “Investigando lab”
bash ~/drills/cpu-high.sh restore
```

Valida: Problem aparece → tratas → Problem OK.

Runbook: [../runbooks/linux-cpu-high.md](../runbooks/linux-cpu-high.md)

---

## Exercício C — Trigger de agent down (15 min)

1. Cria trigger (ou usa o do template) para agent unavailable  
2. No host: `sudo bash ~/drills/agent-down.sh start`  
3. Vê Problem → Ack → `restore` → valida OK  

Runbook: [../runbooks/zabbix-agent-down.md](../runbooks/zabbix-agent-down.md)

---

## Exercício D — Trigger de memória (15 min)

Igual ao CPU, com item de memória / available memory e limiar (ex. available < 10% ou utilization > 90%).  
Drill: `memory-high.sh` + runbook [linux-memory-high](../runbooks/linux-memory-high.md).

---

## Boas práticas (lab = vida real)

| Fazer | Evitar |
|-------|--------|
| Nome claro com prefixo `LAB:` nos teus triggers | `CPU high` genérico sem host |
| WARNING para métrica sem impacto de app | Disaster para CPU > 70% |
| Description com o que fazer | Trigger sem texto |
| Ack ao investigar | Deixar Problems sem dono |
| `restore` no fim do drill | Ir embora com stress a correr |

---

## Onde ver o resultado

- **Monitoring → Problems** — alertas ativos  
- **Monitoring → Hosts** — saúde / availability  
- **Latest data** — métricas a alimentar o trigger  

---

## Depois disto

Catálogo completo (disco, serviço, kubelet, …): [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md)
