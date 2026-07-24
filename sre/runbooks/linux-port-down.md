# Runbook — Porta / health check down

## Sintoma

- Trigger de net.tcp.port / HTTP agent a falhar  
- `ss -lntp` não mostra a porta  
- Load balancer / user vê timeout  

## Impacto

Serviço inacessível mesmo que o processo “pareça” existir. Severidade: **HIGH**.

## Diagnóstico

```bash
ss -lntp | grep -E ':8089|:80' || true
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8089/ || true
sudo systemctl status crl-lab-app --no-pager
```

No lab a app escuta **8089**.

## Mitigação / Resolução

```bash
sudo bash ~/drills/port-down.sh restore
# Prod: restart do serviço, verificar bind address, SG/firewall
```

## Validação

- [ ] `curl` local devolve 200 (ou o código esperado)  
- [ ] Trigger OK  

## Lab

```bash
sudo bash drills/service-down.sh install   # se ainda não instalaste a app
sudo bash drills/port-down.sh start
sudo bash drills/port-down.sh restore
```
