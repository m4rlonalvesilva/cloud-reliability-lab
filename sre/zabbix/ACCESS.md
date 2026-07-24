# Acesso ao Zabbix (lab)

**Apenas laboratório.** Security Group restringe a UI aos CIDRs em `allow_ssh_cidrs`.  
Altera a password do `Admin` no primeiro login.

## Depois do `terraform apply`

1. Abre `cluster-lab.generated.txt` (raiz do repo) e copia a **URL UI** do Zabbix  
   ou: `cd terraform && terraform output zabbix_url`
2. Espera o bootstrap (~5–10 min na 1.ª vez):
   ```bash
   export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
   ./sre/zabbix/scripts/wait-for-zabbix.sh
   ```
3. Browser: `http://<ZABBIX_PUBLIC_IP>/zabbix`

| Campo | Valor (lab) |
|-------|-------------|
| Utilizador | `Admin` |
| Password | `zabbix` |
| DB (interno) | user `zabbix` / password `LabZabbixDB` |

## Logs na EC2

```bash
ssh -i "$SSH_KEY_PATH" ubuntu@$(cd terraform && terraform output -raw zabbix_public_ip)
sudo tail -f /var/log/zabbix-bootstrap.log
sudo systemctl status zabbix-server apache2 zabbix-agent2
sudo tail -f /var/log/zabbix/zabbix_server.log
```

## Status do bootstrap

Ficheiro: `/var/lib/cloud-reliability-lab/zabbix-bootstrap.status`  
Valor esperado: linha a começar por `ready`.

## Próximo passo de estudo

[`../LAB-ALERTAS.md`](../LAB-ALERTAS.md) — criar e tratar alertas.  
Agents nos nós K8s = Passo 4 do [`../PLAN-ZABBIX.md`](../PLAN-ZABBIX.md).
