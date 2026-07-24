#!/usr/bin/env bash
# Stub do bootstrap Zabbix Server (Passo 2).
# Passo 3 substituirá isto pela instalação real (Server + Frontend + PostgreSQL).
set -euo pipefail

echo "[zabbix-stub] Início — instalação completa ainda não implementada"
exec > >(tee /var/log/zabbix-bootstrap.log | logger -t zabbix-bootstrap -s 2>/dev/console) 2>&1

sudo apt-get update -y
sudo apt-get install -y ca-certificates curl

# Marcador para scripts wait futuros
sudo mkdir -p /var/lib/cloud-reliability-lab
echo "stub $(date -u +%Y-%m-%dT%H:%M:%SZ)" | sudo tee /var/lib/cloud-reliability-lab/zabbix-bootstrap.status >/dev/null

echo "[zabbix-stub] EC2 pronta. Próximo: instalar Zabbix Server (ver sre/PLAN-ZABBIX.md Passo 3)."
echo "[zabbix-stub] Concluído"
