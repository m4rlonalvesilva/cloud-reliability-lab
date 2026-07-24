#!/usr/bin/env bash
# Espera o bootstrap do Zabbix Server (status ready + UI HTTP).
# Uso (raiz do repo):
#   export SSH_KEY_PATH="/c/Users/.../sua-chave.pem"
#   ./sre/zabbix/scripts/wait-for-zabbix.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=../../../kubernetes/scripts/lib/cluster-ssh.sh
source "$ROOT_DIR/kubernetes/scripts/lib/cluster-ssh.sh"

die() {
  cluster_ssh_die "$@"
}

INTERVAL_SEC="${WAIT_INTERVAL_SEC:-20}"
MAX_WAIT_SEC="${WAIT_MAX_SEC:-1200}"

for cmd in curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Comando necessário em falta: $cmd" >&2
    die
  fi
done

cluster_ssh_init

TF_DIR="$ROOT_DIR/terraform"
if ! terraform -chdir="$TF_DIR" output -raw enable_zabbix 2>/dev/null | grep -qx 'true'; then
  echo "enable_zabbix não está true no state Terraform." >&2
  die
fi

ZBX_IP="$(terraform -chdir="$TF_DIR" output -raw zabbix_public_ip)"
if [[ -z "$ZBX_IP" || "$ZBX_IP" == "null" ]]; then
  echo "zabbix_public_ip inválido." >&2
  die
fi

run_zabbix_ssh() {
  ssh -i "$SSH_KEY_PATH" \
    -o StrictHostKeyChecking=accept-new \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o ConnectTimeout=15 \
    "ubuntu@${ZBX_IP}" "$@"
}

echo "A testar SSH ao Zabbix ${ZBX_IP}…" >&2
set +e
_ssh_test_out="$(run_zabbix_ssh 'echo ssh_ok' 2>&1)"
_ssh_test_rc=$?
set -e
if [[ "$_ssh_test_rc" -ne 0 ]] || [[ "${_ssh_test_out//$'\r'/}" != *ssh_ok* ]]; then
  echo "SSH ao Zabbix falhou." >&2
  echo "$_ssh_test_out" >&2
  die
fi

echo "== Aguardando Zabbix (UI http://${ZBX_IP}/zabbix ) =="
echo "   Intervalo: ${INTERVAL_SEC}s | Máximo: ${MAX_WAIT_SEC}s"
echo ""

deadline=$((SECONDS + MAX_WAIT_SEC))
while (( SECONDS < deadline )); do
  ts="$(date +%H:%M:%S)"
  status="$(run_zabbix_ssh 'cat /var/lib/cloud-reliability-lab/zabbix-bootstrap.status 2>/dev/null || echo missing' | tr -d '\r')"
  http_code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "http://${ZBX_IP}/zabbix/" || echo 000)"

  echo "[$ts] status=${status} | HTTP ${http_code}"

  if [[ "$status" == ready* ]] && [[ "$http_code" == "200" || "$http_code" == "301" || "$http_code" == "302" ]]; then
    echo ""
    echo "=== Zabbix pronto ==="
    echo "URL: http://${ZBX_IP}/zabbix"
    echo "Login lab: Admin / zabbix  (alterar password)"
    echo "Guia: sre/zabbix/ACCESS.md → sre/LAB-ALERTAS.md"
    printf '\a'
    exit 0
  fi

  if [[ "$status" == failed* ]]; then
    echo "Bootstrap falhou (${status}). Ver: sudo tail -100 /var/log/zabbix-bootstrap.log" >&2
    die
  fi

  sleep "$INTERVAL_SEC"
done

echo "Timeout à espera do Zabbix." >&2
die
