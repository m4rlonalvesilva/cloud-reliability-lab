# Zabbix — lab SRE

## Ordem de estudo (segue esta sequência)

| Passo | Documento |
|-------|-----------|
| 0. **Wizard DB / primeiro acesso** | **[00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md)** ← estás aqui se vires “Configure DB connection” |
| 1. Login | Secção abaixo (`Admin` / `zabbix`) |
| 2. Instalar agents | [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) |
| 3. Entender alertas | [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md) |
| 4. **Configurar alertas na UI** | **[04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md)** |
| 5. Cenários vida real | [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md) |

```text
sre/zabbix/00-PRIMEIRO-ACESSO-WIZARD.md   ← password DB LabZabbixDB, TLS off
sre/zabbix/04-CONFIGURAR-ALERTAS.md       ← criar triggers e praticar
sre/runbooks/ + sre/drills/
```

---

## Login da aplicação web (depois do wizard)

| Campo | Valor |
|-------|--------|
| **URL** | `http://<ZABBIX_PUBLIC_IP>/zabbix` |
| **Utilizador** | `Admin` |
| **Password** | `zabbix` |
| **Versão** | **6.4.0** |

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
./sre/zabbix/scripts/wait-for-zabbix.sh
cd terraform && terraform output zabbix_url
```

No primeiro login, altera a password do `Admin`. Detalhes: [ACCESS.md](ACCESS.md).

### Atalho — ecrã “Configure DB connection”

| Campo | Valor |
|-------|--------|
| Database type | PostgreSQL |
| Database host | `localhost` |
| Database port | `0` |
| Database name | `zabbix` |
| User | `zabbix` |
| Password | `LabZabbixDB` |
| Database TLS encryption | **desligado** |

Guia completo do wizard: [00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md).

---

## Documentos desta pasta

| Ficheiro | Conteúdo |
|----------|----------|
| [00-PRIMEIRO-ACESSO-WIZARD.md](00-PRIMEIRO-ACESSO-WIZARD.md) | Wizard de instalação + DB |
| [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) | Agent nos nós |
| [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md) | Modelo mental + labs |
| [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md) | 12 cenários |
| [04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md) | Criar triggers na UI |
| [ACCESS.md](ACCESS.md) | URL, logs, troubleshooting |
