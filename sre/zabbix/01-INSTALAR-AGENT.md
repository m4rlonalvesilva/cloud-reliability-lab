# 01 — Instalar o Zabbix Agent nas máquinas (passo a passo)

**Quando usar este guia:** o Zabbix Server já está no ar e consegues abrir a UI no browser.

**O que vais aprender:** instalar o agent à mão (como em muitos ambientes reais), apontá-lo para o Server, criar o host na consola e confirmar que as métricas chegam.

**Login da UI (lembrança):**

| Campo | Valor |
|-------|--------|
| URL | `http://<IP_PUBLICO_ZABBIX>/zabbix` |
| Utilizador | `Admin` |
| Password | `zabbix` |

```bash
# No PC (raiz do repo), depois do apply:
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
./sre/zabbix/scripts/wait-for-zabbix.sh
cd terraform && terraform output zabbix_url
```

---

## Visão geral (5 blocos)

```text
1. Anotar IPs (PC)
2. SSH → instalar agent no control-plane
3. SSH → instalar agent no worker
4. Criar os 2 hosts na UI do Zabbix
5. Validar (ícone verde + Latest data)
```

Faz **na ordem**. Não saltes a validação.

---

## Bloco 1 — Anotar os IPs (no teu PC)

Abre o **Git Bash** na raiz do repositório `cloud-reliability-lab`.

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"

echo "=== Zabbix (privado = para o agent) ==="
terraform -chdir=terraform output -raw zabbix_private_ip
terraform -chdir=terraform output -raw zabbix_public_ip
terraform -chdir=terraform output -raw zabbix_url

echo "=== Nós K8s (público = para SSH) ==="
terraform -chdir=terraform output -json ec2_public_ips
```

**Anota num papel / bloco de notas:**

| Nome | Valor (cola o teu) | Para quê |
|------|--------------------|----------|
| `ZABBIX_PRIVATE_IP` | ________________ | O agent fala com o Server **dentro da VPC** |
| `CP_IP` (índice 0) | ________________ | SSH ao control-plane |
| `WORKER_IP` (índice 1) | ________________ | SSH ao worker |

> **Porquê IP privado?** O agent e o Server estão na mesma rede AWS. Usar o IP público aqui costuma falhar ou é má prática.

---

## Bloco 2 — Control-plane: instalar e configurar o agent

### 2.1 Entrar por SSH

No PC:

```bash
CP_IP="$(terraform -chdir=terraform output -json ec2_public_ips | jq -r '.[0]')"
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new ubuntu@"$CP_IP"
```

Estás dentro do control-plane quando o prompt for algo como `ubuntu@ip-10-0-1-...`.

### 2.2 Anotar o IP privado **desta** máquina

Ainda no SSH:

```bash
hostname -I | awk '{print $1}'
```

Anota como `CP_PRIVATE_IP` — vais precisar na UI (Bloco 4).

### 2.3 Repositório oficial Zabbix 6.4 (alinhar com o Server)

```bash
export DEBIAN_FRONTEND=noninteractive
cd /tmp

wget -q -O zabbix-release.deb \
  https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_6.4+ubuntu22.04_all.deb \
  || wget -q -O zabbix-release.deb \
  https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb

sudo dpkg -i zabbix-release.deb
sudo apt-get update -y
```

### 2.4 Instalar o Agent 2 (mesma major do Server: 6.4)

```bash
# Preferir a mesma minor do Server (6.4.0) se disponível:
sudo apt-get install -y zabbix-agent2=1:6.4.0-1+ubuntu22.04 \
  || sudo apt-get install -y zabbix-agent2
sudo apt-mark hold zabbix-agent2 || true
```

### 2.5 Configurar (o passo mais importante)

Substitui `10.0.1.XX` pelo **`ZABBIX_PRIVATE_IP`** que anotaste no Bloco 1.

```bash
ZABBIX_PRIVATE_IP="10.0.1.XX"
HOSTNAME_LAB="control-plane"

sudo sed -i "s/^Server=.*/Server=${ZABBIX_PRIVATE_IP}/" /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^ServerActive=.*/ServerActive=${ZABBIX_PRIVATE_IP}/" /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^#\?Hostname=.*/Hostname=${HOSTNAME_LAB}/" /etc/zabbix/zabbix_agent2.conf
grep -q '^Hostname=' /etc/zabbix/zabbix_agent2.conf \
  || echo "Hostname=${HOSTNAME_LAB}" | sudo tee -a /etc/zabbix/zabbix_agent2.conf
```

**O que significam estas linhas (para aprender):**

| Diretiva | Significado |
|----------|-------------|
| `Server=` | Quem pode pedir dados ao agent (passive check) |
| `ServerActive=` | Para onde o agent envia dados sozinho (active check) |
| `Hostname=` | Nome com que o agent se identifica — **tem de ser igual** ao Host name na UI |

Confirma:

```bash
grep -E '^(Server|ServerActive|Hostname)=' /etc/zabbix/zabbix_agent2.conf
```

Deves ver algo como:

```text
Server=10.0.1.50
ServerActive=10.0.1.50
Hostname=control-plane
```

### 2.6 Arrancar o serviço

```bash
sudo systemctl enable --now zabbix-agent2
sudo systemctl restart zabbix-agent2
sudo systemctl status zabbix-agent2 --no-pager
```

Procura: `Active: active (running)`.

Se falhar:

```bash
sudo journalctl -u zabbix-agent2 -n 50 --no-pager
```

### 2.7 Sair do SSH

```bash
exit
```

---

## Bloco 3 — Worker: repetir a instalação

No PC:

```bash
WORKER_IP="$(terraform -chdir=terraform output -json ec2_public_ips | jq -r '.[1]')"
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new ubuntu@"$WORKER_IP"
```

Repete **2.2 → 2.6**, com estas diferenças:

```bash
# IP privado deste nó (anota como WORKER_PRIVATE_IP)
hostname -I | awk '{print $1}'

# Na config:
ZABBIX_PRIVATE_IP="10.0.1.XX"   # o MESMO IP privado do Zabbix Server
HOSTNAME_LAB="worker"           # nome diferente!
```

Confirma `Hostname=worker`, serviço `active`, depois `exit`.

---

## Bloco 4 — Criar os hosts na UI (browser)

1. Abre a URL do Zabbix e faz login: **Admin** / **zabbix**
2. Menu: **Data collection** → **Hosts**
3. Clica **Create host**

### Host 1 — control-plane

| Campo | Valor |
|-------|--------|
| **Host name** | `control-plane` (igual ao conf!) |
| **Templates** | clica **Select** → escolhe `Linux by Zabbix agent` → **Select** |
| **Host groups** | `Linux servers` (já existe) ou cria `Infrastructure` |
| **Interfaces** | Type **Agent** · IP = `CP_PRIVATE_IP` · Port `10050` |

Clica **Add**.

### Host 2 — worker

Igual, com:

| Campo | Valor |
|-------|--------|
| **Host name** | `worker` |
| **Interfaces** | IP = `WORKER_PRIVATE_IP` · Port `10050` |
| **Templates** | `Linux by Zabbix agent` |

Clica **Add**.

> Se usares sobretudo active checks, podes ligar também o template `Linux by Zabbix agent active`. No lab, começa com `Linux by Zabbix agent`.

---

## Bloco 5 — Validar (não saltes)

1. **Monitoring** → **Hosts**
2. Na coluna do Agent (ZBX), espera ficar **verde** / Available (pode demorar 1–2 minutos)
3. Clica num host → **Latest data**
4. Deves ver itens de CPU, memória, filesystem, etc.

### Teste opcional a partir do Server

```bash
ZBX_IP="$(terraform -chdir=terraform output -raw zabbix_public_ip)"
ssh -i "$SSH_KEY_PATH" ubuntu@"$ZBX_IP"

# Dentro do Zabbix Server — troca pelo IP privado do control-plane:
sudo zabbix_get -s 10.0.1.YY -k agent.ping
# Resposta esperada: 1
```

---

## Se algo falhar

| Sintoma | O que verificar |
|---------|-----------------|
| Agent vermelho / Unknown | `Hostname` na UI ≠ `Hostname=` no conf; IP da interface errado |
| Sem Latest data | Template em falta; espera 1–2 min; `systemctl status zabbix-agent2` |
| `zabbix_get` falha | IP privado errado; agent parado; SG (no lab o `self` já cobre) |
| Não abres a UI | `allow_ssh_cidrs` desatualizado (IP público mudou); `wait-for-zabbix.sh` |

---

## Checklist final

- [ ] Login **Admin** / **zabbix** ok  
- [ ] Agent no **control-plane** (`Hostname=control-plane`)  
- [ ] Agent no **worker** (`Hostname=worker`)  
- [ ] Dois hosts na UI com template Linux  
- [ ] Ícones verdes + Latest data com métricas  

---

## Próximo guia

Com os agents verdes, segue: [`../LAB-ALERTAS.md`](../LAB-ALERTAS.md) — criar triggers, disparar problemas e tratar alertas.

Índice Zabbix: [`README.md`](README.md)
