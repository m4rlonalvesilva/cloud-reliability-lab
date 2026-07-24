# Zabbix — lab SRE

## Depois do Zabbix subir — ordem de estudo

| Passo | Documento |
|-------|-----------|
| 1. Login na UI | Secção abaixo (`Admin` / `zabbix`) |
| 2. Instalar agents | [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) |
| 3. Entender alertas (base) | [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md) |
| 4. **Cenários vida real (12)** | **[03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md)** |
| 5. Mais exercícios | [../LAB-ALERTAS.md](../LAB-ALERTAS.md) |

```text
sre/zabbix/03-CENARIOS-VIDA-REAL.md   ← catálogo
sre/runbooks/                         ← o que fazer
sre/drills/                           ← start / restore
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

No primeiro login, altera a password do `Admin`. Detalhes: [ACCESS.md](ACCESS.md).

---

## Documentos desta pasta

| Ficheiro | Conteúdo |
|----------|----------|
| [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md) | Instalar agent |
| [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md) | Modelo mental + labs base |
| [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md) | 12 cenários com runbook + drill |
| [ACCESS.md](ACCESS.md) | URL, logs, wait |
