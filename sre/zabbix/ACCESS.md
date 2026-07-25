# Acesso ao Zabbix (lab) — complemento

## Começa aqui se estiveres no wizard

→ **[00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md)**

No ecrã **Configure DB connection** usa:

| Campo | Valor |
|-------|--------|
| Database type | PostgreSQL |
| Database host | `localhost` |
| Database port | `0` |
| Database name | `zabbix` |
| User | `zabbix` |
| Password | `LabZabbixDB` |
| Database TLS encryption | **desmarcar** |

Depois: login **Admin** / **zabbix**.

---

Guia principal: **[PASSO-A-PASSO.md](PASSO-A-PASSO.md)** · **[README.md](README.md)**  
Agents: **[01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md)**  
**Configurar alertas:** **[04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md)**  
**Destroy / retomar:** **[05-BACKUP-E-RESTORE.md](05-BACKUP-E-RESTORE.md)**

**Versão do lab:** Zabbix **6.4.0** (PostgreSQL + Apache)

---

## Depois do `terraform apply`

1. URL: `cluster-lab.generated.txt` ou `terraform output zabbix_url`
2. Esperar: `./sre/zabbix/scripts/wait-for-zabbix.sh`
3. Wizard (se aparecer) → [00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md)
4. Login **Admin** / **zabbix**

| Campo | Valor (lab) |
|-------|-------------|
| Utilizador UI | `Admin` |
| Password UI | `zabbix` |
| Password DB (só wizard/interno) | `LabZabbixDB` |

## Logs na EC2

```bash
ssh -i "$SSH_KEY_PATH" ubuntu@$(cd terraform && terraform output -raw zabbix_public_ip)
sudo tail -f /var/log/zabbix-bootstrap.log
sudo systemctl status zabbix-server apache2 zabbix-agent2
```

## Troubleshooting

### UI: `DB type "POSTGRESQL" is not supported... Possible values MYSQL`

```bash
sudo apt-get install -y php-pgsql
sudo systemctl restart apache2
```

### Wizard: falha ao ligar à DB com TLS

Desmarca **Database TLS encryption** (PostgreSQL local sem TLS).
