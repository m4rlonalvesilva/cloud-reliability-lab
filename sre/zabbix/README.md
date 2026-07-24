# Zabbix — lab SRE

## Depois do Zabbix subir — ordem de estudo

| Passo | Documento |
|-------|-----------|
| 1. Login na UI | Secção abaixo (`Admin` / `zabbix`) |
| 2. Instalar agents | **[01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md)** |
| 3. **Entender alertas e corrigir (vida real)** | **[02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md)** |
| 4. Mais exercícios | [../LAB-ALERTAS.md](../LAB-ALERTAS.md) |

```text
sre/zabbix/01-INSTALAR-AGENT.md
sre/zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md
sre/runbooks/   ← o que fazer em cada alerta
sre/drills/     ← start/restore para provocar o alerta
```

---

## Login da aplicação web

| Campo | Valor |
|-------|--------|
| **URL** | `http://<ZABBIX_PUBLIC_IP>/zabbix` |
| **Utilizador** | `Admin` |
| **Password** | `zabbix` |

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
./sre/zabbix/scripts/wait-for-zabbix.sh
cd terraform && terraform output zabbix_url
```

No primeiro login, altera a password do `Admin`.

Mais detalhes (logs, DB): [ACCESS.md](ACCESS.md).

---

## Documentos desta pasta

| Ficheiro | Conteúdo |
|----------|----------|
| [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) | Passo a passo do agent |
| [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md) | Como alertas funcionam + labs agent/CPU/memória |
| [ACCESS.md](ACCESS.md) | URL, wait script, logs |
| [scripts/](scripts/) | install server + wait |
