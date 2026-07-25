#!/usr/bin/env bash
# Atualiza IPs das interfaces Agent nos hosts Zabbix (após novo apply).
# Hosts esperados: control-plane, worker (e opcionalmente "Zabbix server").
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TF="$ROOT_DIR/terraform"

if [[ -z "${ZABBIX_URL:-}" ]]; then
  ZABBIX_URL="$(cd "$TF" && terraform output -raw zabbix_url 2>/dev/null || true)"
fi
: "${ZABBIX_URL:?Defina ZABBIX_URL}"
: "${ZABBIX_USER:=Admin}"
: "${ZABBIX_PASSWORD:?Defina ZABBIX_PASSWORD}"
: "${SSH_KEY_PATH:?Defina SSH_KEY_PATH}"

for cmd in curl jq terraform ssh; do
  command -v "$cmd" >/dev/null || { echo "Falta: $cmd" >&2; exit 1; }
done

API="${ZABBIX_URL%/}/api_jsonrpc.php"
IPS_JSON="$(terraform -chdir="$TF" output -json ec2_public_ips)"
ZBX_PRIV="$(terraform -chdir="$TF" output -raw zabbix_private_ip)"

SSH_OPTS=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ConnectTimeout=15
)

private_ip_of() {
  local public_ip="$1"
  ssh "${SSH_OPTS[@]}" "ubuntu@${public_ip}" "hostname -I | awk '{print \$1}'" | tr -d '\r'
}

zbx() {
  local method="$1"
  local params="$2"
  local auth_json="${3:-null}"
  curl -sS -H 'Content-Type: application/json-rpc' \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"${method}\",\"params\":${params},\"auth\":${auth_json},\"id\":1}" \
    "$API"
}

LOGIN="$(zbx user.login "{\"username\":\"${ZABBIX_USER}\",\"password\":\"${ZABBIX_PASSWORD}\"}" null)"
if echo "$LOGIN" | jq -e '.error' >/dev/null 2>&1; then
  echo "$LOGIN" | jq . >&2
  exit 1
fi
AUTH="$(echo "$LOGIN" | jq -c '.result')"

update_host_ip() {
  local host_name="$1"
  local new_ip="$2"
  echo "[sync] $host_name → $new_ip"
  local host_json iface_id host_id
  host_json="$(zbx host.get "{\"output\":[\"hostid\"],\"selectInterfaces\":[\"interfaceid\",\"ip\",\"type\"],\"filter\":{\"host\":[\"${host_name}\"]}}" "$AUTH")"
  host_id="$(echo "$host_json" | jq -r '.result[0].hostid // empty')"
  if [[ -z "$host_id" ]]; then
    echo "[sync] Host '$host_name' não existe na UI — cria/restaura primeiro."
    return 0
  fi
  iface_id="$(echo "$host_json" | jq -r '.result[0].interfaces[] | select(.type=="1") | .interfaceid' | head -1)"
  if [[ -z "$iface_id" ]]; then
    echo "[sync] Sem interface Agent no host $host_name"
    return 0
  fi
  local resp
  resp="$(zbx hostinterface.update "{\"interfaceid\":\"${iface_id}\",\"ip\":\"${new_ip}\"}" "$AUTH")"
  if echo "$resp" | jq -e '.error' >/dev/null 2>&1; then
    echo "$resp" | jq . >&2
    exit 1
  fi
  echo "[sync] OK $host_name"
}

CP_PUB="$(echo "$IPS_JSON" | jq -r '.[0]')"
CP_PRIV="$(private_ip_of "$CP_PUB")"
update_host_ip "control-plane" "$CP_PRIV"

if [[ "$(echo "$IPS_JSON" | jq 'length')" -gt 1 ]]; then
  W_PUB="$(echo "$IPS_JSON" | jq -r '.[1]')"
  W_PRIV="$(private_ip_of "$W_PUB")"
  update_host_ip "worker" "$W_PRIV"
fi

# Host local do server (nome default do agent no bootstrap)
update_host_ip "Zabbix server" "$ZBX_PRIV" || true

zbx user.logout "[]" "$AUTH" >/dev/null || true
echo "[sync] Feito. Confirma Monitoring → Hosts (agent verde)."
