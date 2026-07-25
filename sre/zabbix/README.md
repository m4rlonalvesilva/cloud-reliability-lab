# Zabbix — lab SRE

## Começa aqui

**Passo a passo completo (apply → alertas → backup → destroy → retomar):**  
→ **[PASSO-A-PASSO.md](PASSO-A-PASSO.md)**

---

## Ordem dos guias detalhados

| Passo | Documento |
|-------|-----------|
| 0. Wizard DB | [00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md) |
| 1. Login | Secção abaixo |
| 2. Agents | [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) ou `install-agents-remote.sh` |
| 3. Entender alertas | [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md) |
| 4. Configurar alertas | [04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md) |
| 5. Cenários vida real | [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md) |
| 6. Backup / destroy / restore | [05-BACKUP-E-RESTORE.md](05-BACKUP-E-RESTORE.md) |

---

## Controlo de custo

```bash
# Antes do destroy — grava hosts/triggers no Git
export ZABBIX_PASSWORD=zabbix
./sre/zabbix/scripts/backup-zabbix-config.sh
git add sre/zabbix/config-export && git commit -m "chore: backup config Zabbix"
cd terraform && terraform destroy
```

Ao voltar: ver secção 8 de [PASSO-A-PASSO.md](PASSO-A-PASSO.md).

---

## Login

| Campo | Valor |
|-------|--------|
| **URL** | `http://<ZABBIX_PUBLIC_IP>/zabbix` |
| **Utilizador** | `Admin` |
| **Password** | `zabbix` |
| **Versão** | **6.4.0** |
| **Password DB (wizard)** | `LabZabbixDB` (TLS **off**) |

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
./sre/zabbix/scripts/wait-for-zabbix.sh
cd terraform && terraform output zabbix_url
```

---

## Documentos

| Ficheiro | Conteúdo |
|----------|----------|
| **[PASSO-A-PASSO.md](PASSO-A-PASSO.md)** | Guia único ponta a ponta |
| [00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md) | Wizard |
| [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) | Agent manual + hosts |
| [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md) | Modelo mental |
| [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md) | 12 cenários |
| [04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md) | Criar triggers |
| [05-BACKUP-E-RESTORE.md](05-BACKUP-E-RESTORE.md) | Destroy sem perder config |
| [ACCESS.md](ACCESS.md) | URL, logs |
| [config-export/](config-export/) | Backup versionado |
