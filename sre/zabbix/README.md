# Zabbix — lab SRE

## Depois do Zabbix subir — começa aqui

| Passo | Documento |
|-------|-----------|
| 1. Login na UI | Secção abaixo |
| 2. **Instalar o agent nas máquinas (aprender à mão)** | **[01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md)** ← guia completo |
| 3. Criar e tratar alertas | [../LAB-ALERTAS.md](../LAB-ALERTAS.md) |

Caminho no repo:

```text
sre/zabbix/01-INSTALAR-AGENT.md
```

Também aparece em `cluster-lab.generated.txt` depois do `terraform apply`.

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
| **[01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md)** | Passo a passo: agent no control-plane e worker + hosts na UI |
| [ACCESS.md](ACCESS.md) | URL, wait script, logs |
| [scripts/](scripts/) | `install-zabbix-server.sh`, `wait-for-zabbix.sh` |
