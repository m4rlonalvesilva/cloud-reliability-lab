# 00 — Primeiro acesso (wizard de instalação)

**Quando aparece:** ao abrir a UI pela 1.ª vez e o ficheiro `/etc/zabbix/web/zabbix.conf.php` ainda não existir (ou foi apagado).

**URL:** `http://<ZABBIX_PUBLIC_IP>/zabbix`  
**Versão do lab:** 6.4.0

Se já fores direto ao login `Admin` / `zabbix`, podes saltar este guia e ir para [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md).

---

## Ordem do wizard (sidebar)

1. Welcome  
2. Check of pre-requisites  
3. **Configure DB connection** ← ecrã da base de dados  
4. Settings  
5. Pre-installation summary  
6. Install  

---

## Passo 1 — Welcome

Clica **Next step**.

---

## Passo 2 — Check of pre-requisites

Confirma que os requisitos estão a verde (OK).  
Se `php-pgsql` faltar, na EC2:

```bash
sudo apt-get install -y php-pgsql
sudo systemctl restart apache2
```

Clica **Next step**.

---

## Passo 3 — Configure DB connection (valores do lab)

Preenche **exatamente** assim:

| Campo | Valor |
|-------|--------|
| **Database type** | `PostgreSQL` |
| **Database host** | `localhost` |
| **Database port** | `0` (usa a porta default 5432) |
| **Database name** | `zabbix` |
| **Database schema** | *(deixar vazio)* |
| **Store credentials in** | `Plain text` |
| **User** | `zabbix` |
| **Password** | `LabZabbixDB` |
| **Database TLS encryption** | **desmarcar** (PostgreSQL local, sem TLS) |
| **Verify database certificate** | desmarcado |

> **Importante:** com TLS ligado para `localhost` sem certificados, a ligação à DB falha. Deixa TLS **off**.

Clica **Next step**.

---

## Passo 4 — Settings

| Campo | Valor sugerido |
|-------|----------------|
| **Zabbix server name** | `cloud-reliability-lab` (ou o que preferires) |
| Timezone | `America/Sao_Paulo` (se pedir) |
| Tema / defaults | podes deixar |

Clica **Next step**.

---

## Passo 5 — Pre-installation summary

Revisa e clica **Next step**.

---

## Passo 6 — Install

No fim clica **Finish** (ou equivalente).

---

## Login após o wizard

| Campo | Valor |
|-------|--------|
| **Username** | `Admin` |
| **Password** | `zabbix` |

Altera a password no primeiro acesso (`User settings` / perfil).

---

## Se o wizard pedir de novo

Na EC2 Zabbix:

```bash
ls -l /etc/zabbix/web/zabbix.conf.php
sudo systemctl status zabbix-server postgresql apache2 --no-pager
```

O bootstrap (`install-zabbix-server.sh`) normalmente cria este ficheiro para saltar o wizard. Se não existir, completa o wizard com a tabela acima.

---

## Próximos passos (aprendizagem)

1. **Agents** nos nós → [01-INSTALAR-AGENT.md](01-INSTALAR-AGENT.md)  
2. **Configurar e tratar alertas** → [02-ENTENDER-E-TRATAR-ALERTAS.md](02-ENTENDER-E-TRATAR-ALERTAS.md)  
3. **Criar o teu primeiro trigger** → [04-CONFIGURAR-ALERTAS.md](04-CONFIGURAR-ALERTAS.md)  
4. Cenários vida real → [03-CENARIOS-VIDA-REAL.md](03-CENARIOS-VIDA-REAL.md)  
