# Acesso ao Zabbix (lab) — complemento

Guia principal (login web): **[README.md](README.md)**  
**Depois do Zabbix subir → agents:** **[01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md)**

**Login UI:** utilizador `Admin` · password `zabbix`  
**URL:** `http://<ZABBIX_PUBLIC_IP>/zabbix` (ver `terraform output zabbix_url`)  
**Versão do lab:** Zabbix **6.4.0** (PostgreSQL + Apache)

---

## Depois do `terraform apply`

1. Abre `cluster-lab.generated.txt` (raiz do repo) e copia a **URL UI** do Zabbix  
   ou: `cd terraform && terraform output zabbix_url`
2. Espera o bootstrap (~5–10 min na 1.ª vez):
   ```bash
   export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
   ./sre/zabbix/scripts/wait-for-zabbix.sh
   ```
3. Browser + login (ver tabela no [README.md](README.md))

| Campo | Valor (lab) |
|-------|-------------|
| Utilizador | `Admin` |
| Password | `zabbix` |
| DB (interno, não é o login web) | user `zabbix` / password `LabZabbixDB` |

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

## Troubleshooting

### UI: `DB type "POSTGRESQL" is not supported... Possible values MYSQL`

Falta o módulo PHP PostgreSQL. Na EC2 Zabbix:

```bash
sudo apt-get install -y php-pgsql
sudo systemctl restart apache2
```

(O bootstrap atual já instala `php-pgsql` em novas máquinas.)

1. Agents manuais: [README.md](README.md)  
2. Alertas: [`../LAB-ALERTAS.md`](../LAB-ALERTAS.md)
