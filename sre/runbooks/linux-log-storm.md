# Runbook — Tempestade de logs (disco a crescer)

## Sintoma

- Disco a subir depressa; logs enormes  
- App em loop de erro a escrever  
- Parece “disco cheio”, causa = logging  

## Impacto

Mesmo que disco cheio; root cause diferente. Severidade: **HIGH**.

## Diagnóstico

```bash
df -h
sudo du -sh /var/log/* 2>/dev/null | sort -h | tail -15
sudo journalctl --disk-usage
ls -lh /var/tmp/crl-lab-logs 2>/dev/null | tail
```

## Mitigação / Resolução

```bash
sudo bash ~/drills/log-storm.sh restore
# Prod: corrigir a app que spamma; vacuum journal; logrotate
sudo journalctl --vacuum-size=100M
```

## Validação

- [ ] Espaço livre  
- [ ] Taxa de crescimento estabilizada  
- [ ] Problem OK  

## Lab

```bash
bash drills/log-storm.sh start
bash drills/log-storm.sh restore
```
