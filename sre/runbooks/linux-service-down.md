# Runbook — Serviço systemd parado

## Sintoma

- Trigger “service is down” / systemd unit inactive  
- App não responde; `systemctl status` mostra failed/inactive  
- No lab usamos a unit `crl-lab-app.service` (app fictícia)  

## Impacto

Funcionalidade da app indisponível. Severidade: **HIGH**.

## Diagnóstico

```bash
sudo systemctl status crl-lab-app --no-pager
sudo journalctl -u crl-lab-app -n 50 --no-pager
systemctl is-active crl-lab-app
```

## Causas possíveis

- `systemctl stop` / crash / OOM  
- Dependência em falta  
- Drill de lab  

## Mitigação / Resolução

```bash
sudo systemctl start crl-lab-app
sudo systemctl enable crl-lab-app
sudo systemctl status crl-lab-app --no-pager
```

Se a unit não existir: `sudo bash drills/service-down.sh install`

## Validação

- [ ] `active (running)`  
- [ ] Problem OK  
- [ ] (se porta) health check responde  

## Lab

```bash
sudo bash drills/service-down.sh install   # uma vez
sudo bash drills/service-down.sh start     # para o serviço (incidente)
sudo bash drills/service-down.sh restore   # volta a subir
```
