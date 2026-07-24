# Runbook — Memória alta / disponível baixa (Linux)

## Sintoma

- Problem de memory utilization high / available memory low  
- `free -h` mostra pouca memória disponível  
- Em casos graves: OOM Killer, processos mortos, pods Evicted  

## Impacto

- Risco de instabilidade e kills pelo kernel  
- Apps podem falhar de forma intermitente  

Severidade sugerida: **WARNING** → **HIGH** se houver OOM ou restarts.

## Diagnóstico

```bash
free -h
ps aux --sort=-%mem | head -15
smem -rk 2>/dev/null || true
dmesg -T | grep -iE 'oom|killed process' | tail -20
# K8s:
# kubectl get pods -A --field-selector=status.phase!=Running | head
# kubectl describe node <node> | sed -n '/Allocated resources/,/Events/p'
```

## Causas possíveis

- Memory leak  
- Cache/buffers altos (em Linux muita “used” pode ser cache — olhar **available**)  
- Workload a mais no nó  
- Drill de lab  

## Mitigação

**Lab:**

```bash
# Parar stress de memória do drill
sudo bash sre/drills/memory-high.sh restore
# ou matar o processo que criaste de propósito
```

**Produção:**

- Reiniciar serviço com leak (janela)  
- Reduzir réplicas / limits no K8s  
- Evitar `echo 3 > /proc/sys/vm/drop_caches` como “fix” habitual (mascara o problema)  

## Resolução

- Corrigir leak / dimensionar / ajustar limits  
- Lab: restore do drill  

## Validação

- [ ] `free -h` — available sobe  
- [ ] Sem novas linhas OOM no `dmesg`  
- [ ] Latest data + Problem OK  

## Escalonamento

- OOM recorrente → app owner + capacidade  
- Nó K8s sob pressão → platform (mais nós, requests/limits)  

## Lab — reproduzir / restaurar

```bash
sudo bash sre/drills/memory-high.sh start    # consome RAM de forma limitada
sudo bash sre/drills/memory-high.sh restore
```

Guia: [../zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md](../zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md)
