#!/usr/bin/env bash
# Importa configuração Zabbix a partir de sre/zabbix/config-export/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
IN_DIR="${ZABBIX_EXPORT_DIR:-$ROOT_DIR/sre/zabbix/config-export}"

if [[ -z "${ZABBIX_URL:-}" ]]; then
  ZABBIX_URL="$(cd "$ROOT_DIR/terraform" && terraform output -raw zabbix_url 2>/dev/null || true)"
fi
: "${ZABBIX_URL:?Defina ZABBIX_URL}"
: "${ZABBIX_USER:=Admin}"
: "${ZABBIX_PASSWORD:?Defina ZABBIX_PASSWORD}"

for cmd in curl jq; do
  command -v "$cmd" >/dev/null || { echo "Falta: $cmd" >&2; exit 1; }
done

API="${ZABBIX_URL%/}/api_jsonrpc.php"

zbx() {
  local method="$1"
  local params="$2"
  local auth_json="${3:-null}"
  curl -sS -H 'Content-Type: application/json-rpc' \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"${method}\",\"params\":${params},\"auth\":${auth_json},\"id\":1}" \
    "$API"
}

echo "[restore] Login em $ZABBIX_URL …"
LOGIN="$(zbx user.login "{\"username\":\"${ZABBIX_USER}\",\"password\":\"${ZABBIX_PASSWORD}\"}" null)"
if echo "$LOGIN" | jq -e '.error' >/dev/null 2>&1; then
  echo "$LOGIN" | jq . >&2
  exit 1
fi
AUTH="$(echo "$LOGIN" | jq -c '.result')"

RULES='{
  "host_groups":{"createMissing":true,"updateExisting":true},
  "hosts":{"createMissing":true,"updateExisting":true},
  "templates":{"createMissing":true,"updateExisting":true},
  "template_groups":{"createMissing":true,"updateExisting":true},
  "items":{"createMissing":true,"updateExisting":true},
  "triggers":{"createMissing":true,"updateExisting":true},
  "discoveryRules":{"createMissing":true,"updateExisting":true},
  "graphs":{"createMissing":true,"updateExisting":true},
  "valueMaps":{"createMissing":true,"updateExisting":true},
  "httptests":{"createMissing":true,"updateExisting":true}
}'

import_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "[restore] Skip (não existe): $file"
    return 0
  fi
  if [[ ! -s "$file" ]]; then
    echo "[restore] Skip (vazio): $file"
    return 0
  fi
  # {} sem zabbix_export
  if ! grep -q 'zabbix_export' "$file" 2>/dev/null; then
    echo "[restore] Skip (sem zabbix_export): $file"
    return 0
  fi

  echo "[restore] A importar $(basename "$file") …"
  local params resp
  params="$(jq -nc --argjson rules "$RULES" --rawfile source "$file" \
    '{format:"json", rules:$rules, source:$source}')"

  resp="$(zbx configuration.import "$params" "$AUTH")"
  if echo "$resp" | jq -e '.error' >/dev/null 2>&1; then
    echo "$resp" | jq . >&2
    exit 1
  fi
  echo "[restore] OK $(basename "$file")"
}

import_file "$IN_DIR/templates.json"
import_file "$IN_DIR/hosts.json"

zbx user.logout "[]" "$AUTH" >/dev/null || true
echo "[restore] Feito. Seguinte: ./sre/zabbix/scripts/sync-host-agent-ips.sh"
