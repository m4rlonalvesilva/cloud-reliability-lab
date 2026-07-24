# Zabbix — lab SRE

## Login da aplicação web

| Campo | Valor |
|-------|--------|
| **URL** | `http://<ZABBIX_PUBLIC_IP>/zabbix` |
| **Utilizador** | `Admin` |
| **Password** | `zabbix` |

Como obter o IP/URL:

```bash
# inventário gerado no apply
cat cluster-lab.generated.txt

# ou
cd terraform && terraform output zabbix_url
cd terraform && terraform output -raw zabbix_public_ip
```

Esperar o Server ficar pronto (1.ª vez ~5–10 min):

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
./sre/zabbix/scripts/wait-for-zabbix.sh
```

**Importante (lab):** no primeiro login, altera a password do `Admin`  
(`User settings` → `Profile` ou `Users` → `Admin`).

Detalhes extras (DB, logs): [ACCESS.md](ACCESS.md).

---

## Instalação manual do Agent (control-plane e worker)

Objetivo: instalar o **Zabbix Agent 2** nas EC2 do Kubernetes e registá-las na UI.

Repete os passos **em cada máquina** (control-plane e worker).

### 0) Dados que vais precisar

No teu PC (Git Bash, raiz do repo):

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"

# IP privado do Zabbix Server (os agents usam este IP na VPC)
terraform -chdir=terraform output -raw zabbix_private_ip

# IPs públicos dos nós K8s (SSH)
terraform -chdir=terraform output -json ec2_public_ips
# índice 0 = control-plane | índice 1 = worker
```

Anota:

| Variável | Exemplo | Onde usar |
|----------|---------|-----------|
| `ZABBIX_PRIVATE_IP` | `10.0.1.50` | `Server=` e `ServerActive=` no agent |
| Hostname do host | `control-plane` / `worker` | conf do agent **e** nome do host na UI |

O Security Group do lab já permite tráfego entre as EC2 (`self`).  
Não é preciso abrir 10050/10051 para a Internet.

---

### 1) SSH na máquina alvo

**Control-plane:**

```bash
CP_IP="$(terraform -chdir=terraform output -json ec2_public_ips | jq -r '.[0]')"
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new ubuntu@"$CP_IP"
```

**Worker:**

```bash
WORKER_IP="$(terraform -chdir=terraform output -json ec2_public_ips | jq -r '.[1]')"
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new ubuntu@"$WORKER_IP"
```

---

### 2) Adicionar o repositório Zabbix 7.0 (Ubuntu 22.04)

No servidor (SSH):

```bash
export DEBIAN_FRONTEND=noninteractive
cd /tmp
wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu22.04_all.deb \
  -O zabbix-release.deb \
  || wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu22.04_all.deb \
  -O zabbix-release.deb

sudo dpkg -i zabbix-release.deb
sudo apt-get update -y
```

---

### 3) Instalar o Agent 2

```bash
sudo apt-get install -y zabbix-agent2
```

---

### 4) Configurar o agent

Substitui `ZABBIX_PRIVATE_IP` e o `Hostname` (usa o mesmo nome que vais criar na UI).

**No control-plane:**

```bash
ZABBIX_PRIVATE_IP="10.0.1.XX"   # output zabbix_private_ip
HOSTNAME_LAB="control-plane"

sudo sed -i "s/^Server=.*/Server=${ZABBIX_PRIVATE_IP}/" /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^ServerActive=.*/ServerActive=${ZABBIX_PRIVATE_IP}/" /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^Hostname=.*/Hostname=${HOSTNAME_LAB}/" /etc/zabbix/zabbix_agent2.conf

# Se Hostname estiver comentado:
grep -q '^Hostname=' /etc/zabbix/zabbix_agent2.conf \
  || echo "Hostname=${HOSTNAME_LAB}" | sudo tee -a /etc/zabbix/zabbix_agent2.conf
```

**No worker:** igual, com `HOSTNAME_LAB="worker"`.

Confirma:

```bash
grep -E '^(Server|ServerActive|Hostname)=' /etc/zabbix/zabbix_agent2.conf
```

Exemplo esperado (control-plane):

```text
Server=10.0.1.XX
ServerActive=10.0.1.XX
Hostname=control-plane
```

---

### 5) Arrancar o serviço

```bash
sudo systemctl enable --now zabbix-agent2
sudo systemctl restart zabbix-agent2
sudo systemctl status zabbix-agent2 --no-pager
sudo journalctl -u zabbix-agent2 -n 30 --no-pager
```

Deve ficar **active (running)**.

---

### 6) Criar o host na UI do Zabbix

1. Login: **Admin** / **zabbix**
2. **Data collection** → **Hosts** → **Create host**
3. Preenche:

| Campo | Control-plane | Worker |
|-------|---------------|--------|
| Host name | `control-plane` | `worker` |
| Visible name | (opcional) | (opcional) |
| Groups | `Linux servers` (ou cria `Infrastructure`) | idem |
| Interfaces → Agent | IP **privado** da EC2 K8s | idem |
| Port | `10050` | `10050` |

4. Separador **Templates** → adiciona:
   - `Linux by Zabbix agent`  
   (ou `Linux by Zabbix agent active`, conforme preferires passive/active)
5. **Add** / **Update**

IP privado do nó (na EC2, via SSH):

```bash
hostname -I | awk '{print $1}'
```

O **Host name** na UI tem de coincidir com o `Hostname=` do ficheiro de conf do agent (passo 4), sobretudo com items **active**.

---

### 7) Validar

Na UI: **Monitoring** → **Hosts**

- Availability do Agent: ícone verde / Available  
- **Latest data** do host: CPU, memória, disco, etc.

No Server Zabbix (opcional):

```bash
# SSH à EC2 Zabbix
sudo -u zabbix zabbix_get -s <IP_PRIVADO_DO_NO> -k agent.ping
# deve devolver: 1
```

---

### 8) Checklist rápido

- [ ] UI abre e login **Admin** / **zabbix** funciona  
- [ ] Agent instalado no control-plane e no worker  
- [ ] `Server` / `ServerActive` = IP **privado** do Zabbix  
- [ ] `Hostname` = nome do host na UI  
- [ ] Hosts criados com interface Agent :10050  
- [ ] Template Linux ligado  
- [ ] Agent Available (verde)

---

## Ordem sugerida na sessão de lab

1. `terraform apply` + `./sre/zabbix/scripts/wait-for-zabbix.sh`  
2. Login na UI (credenciais no topo deste README)  
3. Instalar agent nas 2 máquinas (secções 1–7)  
4. Seguir [`../LAB-ALERTAS.md`](../LAB-ALERTAS.md) — criar e tratar alertas  

## Referências

- [ACCESS.md](ACCESS.md) — URL, logs, password da DB (lab)  
- [../PLAN-ZABBIX.md](../PLAN-ZABBIX.md) — plano da fase  
- [../LAB-ALERTAS.md](../LAB-ALERTAS.md) — exercícios de alertas  
