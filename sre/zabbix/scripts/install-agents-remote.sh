#!/usr/bin/env bash
# Instala zabbix-agent2 6.4.0 nos nós K8s via SSH (após terraform apply).
# Uso:
#   export SSH_KEY_PATH=...
#   ./sre/zabbix/scripts/install-agents-remote.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=../../../kubernetes/scripts/lib/cluster-ssh.sh
source "$ROOT_DIR/kubernetes/scripts/lib/cluster-ssh.sh"

cluster_ssh_init

TF="$ROOT_DIR/terraform"
ZABBIX_PRIVATE_IP="$(terraform -chdir="$TF" output -raw zabbix_private_ip)"
IPS_JSON="$(terraform -chdir="$TF" output -json ec2_public_ips)"
N="$(echo "$IPS_JSON" | jq 'length')"

SSH_OPTS=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ConnectTimeout=20
)

install_on() {
  local public_ip="$1"
  local hostname_lab="$2"
  echo "[agents] === $hostname_lab ($public_ip) → Server $ZABBIX_PRIVATE_IP ==="
  ssh "${SSH_OPTS[@]}" "ubuntu@${public_ip}" bash -s <<REMOTE
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
ZABBIX_PRIVATE_IP='${ZABBIX_PRIVATE_IP}'
HOSTNAME_LAB='${hostname_lab}'

if systemctl is-active --quiet zabbix-agent2 2>/dev/null; then
  echo "[agents] agent2 já active — a reconfigurar Server/Hostname"
else
  cd /tmp
  wget -q -O zabbix-release.deb \\
    https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_6.4+ubuntu22.04_all.deb \\
    || wget -q -O zabbix-release.deb \\
    https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
  sudo dpkg -i zabbix-release.deb
  sudo apt-get update -y
  sudo apt-get install -y zabbix-agent2=1:6.4.0-1+ubuntu22.04 \\
    || sudo apt-get install -y zabbix-agent2
  sudo apt-mark hold zabbix-agent2 || true
fi

sudo sed -i "s/^Server=.*/Server=\${ZABBIX_PRIVATE_IP}/" /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^ServerActive=.*/ServerActive=\${ZABBIX_PRIVATE_IP}/" /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^#\\?Hostname=.*/Hostname=\${HOSTNAME_LAB}/" /etc/zabbix/zabbix_agent2.conf
grep -q '^Hostname=' /etc/zabbix/zabbix_agent2.conf \\
  || echo "Hostname=\${HOSTNAME_LAB}" | sudo tee -a /etc/zabbix/zabbix_agent2.conf

sudo systemctl enable --now zabbix-agent2
sudo systemctl restart zabbix-agent2
sudo systemctl is-active zabbix-agent2
grep -E '^(Server|ServerActive|Hostname)=' /etc/zabbix/zabbix_agent2.conf
REMOTE
}

# índice 0 = control-plane, resto = worker-N
for ((i = 0; i < N; i++)); do
  ip="$(echo "$IPS_JSON" | jq -r ".[$i]")"
  if [[ "$i" -eq 0 ]]; then
    name="control-plane"
  else
    name="worker"
    [[ "$N" -gt 2 ]] && name="worker-${i}"
  fi
  install_on "$ip" "$name"
done

echo "[agents] Feito. Cria/restaura hosts na UI ou corre restore + sync-host-agent-ips."
