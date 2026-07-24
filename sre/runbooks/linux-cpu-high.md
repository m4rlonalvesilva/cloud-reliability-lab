# Runbook — CPU alta (Linux)

## Sintoma

- Problem de CPU utilization / load high (nome depende do template)  
- Latest data: CPU ~90–100%  
- Em prod: possível lentidão, timeouts, filas  

## Impacto

- Máquina degradada; apps podem ficar lentas  
- **Sozinha** raramente é CRITICAL — sobe severidade se houver erros 5xx / SLO a quebrar  

Severidade sugerida: **WARNING** (subir para HIGH se houver impacto de serviço).

## Diagnóstico

```bash
uptime
nproc
top -b -n1 | head -20
ps aux --sort=-%cpu | head -15
# Se for nó K8s:
# kubectl top nodes
# kubectl top pods -A --sort-by=cpu | head
```

Perguntas:

1. É um processo conhecido (app, backup, stress de lab)?  
2. É pico curto ou sustentado?  
3. Há impacto (latência, erros)?  

## Causas possíveis

- Processo runaway / loop  
- Job batch / compressão / compile  
- Contenção (muitos pods no mesmo nó)  
- Drill de lab (`yes`, `stress`)  

## Mitigação

**Lab / processo óbvio de stress:**

```bash
pkill -f '^yes$' || true
# ou pkill do teu drill
```

**Produção (exemplos):**

- Reiniciar o serviço culpado (com janela / owner)  
- Limitar CPU (cgroup, K8s limits)  
- Escalar horizontalmente / mover workload  
- **Não** matar processos à sorte sem saber o que são  

## Resolução

- Lab: parar o drill (`cpu-high.sh restore`)  
- Prod: corrigir root cause (bug, capacidade, schedule do job)  

## Validação

- [ ] `top` mostra CPU a descer  
- [ ] Latest data no Zabbix a normalizar  
- [ ] Problem OK  
- [ ] App/SLO ok (se aplicável)  

## Escalonamento

- Não identificas o processo e CPU continua alta → escalar app owner / capacity  
- Nó K8s com muitos pods → platform / HPA / mais nodes  

## Lab — reproduzir / restaurar

No host (SSH), a partir do repo ou copia o script:

```bash
sudo bash sre/drills/cpu-high.sh start     # sobe CPU ~3 min (ou até restore)
sudo bash sre/drills/cpu-high.sh restore   # pára o stress
```

Guia: [../zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md](../zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md)
