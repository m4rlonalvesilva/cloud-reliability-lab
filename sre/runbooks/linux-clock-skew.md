# Runbook — Relógio dessincronizado (NTP/chrony)

## Sintoma

- Offset de tempo alto; alertas de time sync  
- Sintomas reais: certificados “não válidos ainda/já”, logs fora de ordem, auth a falhar  

## Impacto

Subtil mas grave em clusters e TLS. Severidade: **WARNING → HIGH**.

## Diagnóstico

```bash
timedatectl status
timedatectl timesync-status 2>/dev/null || true
chronyc tracking 2>/dev/null || true
date -u
```

## Mitigação / Resolução

```bash
sudo bash ~/drills/clock-skew.sh restore
# Prod:
sudo systemctl restart systemd-timesyncd
# ou chronyd; verificar firewall NTP
timedatectl status
```

## Validação

- [ ] `System clock synchronized: yes` (ou equivalente chrony)  
- [ ] Problem OK  

## Lab

```bash
sudo bash drills/clock-skew.sh start
sudo bash drills/clock-skew.sh restore
```
