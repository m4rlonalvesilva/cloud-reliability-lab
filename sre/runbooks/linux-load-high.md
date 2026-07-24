# Runbook — Load average alta

## Sintoma

- Trigger de load average (1/5/15 min) acima do nº de CPUs  
- Sistema “pesado”; `uptime` com load alto  
- Pode coexistir com CPU alta ou I/O wait  

## Impacto

Latência e filas. Severidade: **WARNING** (HIGH se app impactada).

## Diagnóstico

```bash
uptime
nproc
top -b -n1 | head -25
vmstat 1 5
iostat -xz 1 3 2>/dev/null || true
```

Load alta + CPU baixa → muitas vezes **I/O wait** ou uninterruptible sleep (disco).

## Mitigação / Resolução

```bash
bash ~/drills/load-high.sh restore
# Prod: reduzir concorrência, corrigir I/O, matar job runaway
```

## Validação

- [ ] `uptime` a normalizar  
- [ ] Problem OK  

## Lab

```bash
bash drills/load-high.sh start
bash drills/load-high.sh restore
```
