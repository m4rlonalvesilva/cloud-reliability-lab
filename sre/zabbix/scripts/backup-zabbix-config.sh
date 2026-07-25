#!/usr/bin/env bash
# Exporta configuração Zabbix (hosts + templates) para sre/zabbix/config-export/
# Uso:
#   export ZABBIX_URL=http://x.x.x.x/zabbix
#   export ZABBIX_USER=Admin
#   export ZABBIX_PASSWORD=zabbix
#   ./sre/zabbix/scripts/backup-zabbix-config.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUT_DIR="${ZABBIX_EXPORT_DIR:-$ROOT_DIR/sre/zabbix/config-export}"

if [[ -z "${ZABBIX_URL:-}" ]]; then
  ZABBIX_URL="$(cd "$ROOT_DIR/terraform" && terraform output -raw zabbix_url 2>/dev/null || true)"
fi
: "${ZABBIX_URL:?Defina ZABBIX_URL ou tenha terraform output zabbix_url}"
: "${ZABBIX_USER:=Admin}"
: "${ZABBIX_PASSWORD:?Defina ZABBIX_PASSWORD}"

for cmd in curl jq; do
  command -v "$cmd" >/dev/null || { echo "Falta: $cmd" >&2; exit 1; }
done

API="${ZABBIX_URL%/}/api_jsonrpc.php"
mkdir -p "$OUT_DIR"

zbx() {
  local method="$1"
  local params="$2"
  local auth_json="${3:-null}"
  curl -sS -H 'Content-Type: application/json-rpc' \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"${method}\",\"params\":${params},\"auth\":${auth_json},\"id\":1}" \
    "$API"
}

echo "[backup] Login em $ZABBIX_URL …"
LOGIN="$(zbx user.login "{\"username\":\"${ZABBIX_USER}\",\"password\":\"${ZABBIX_PASSWORD}\"}" null)"
if echo "$LOGIN" | jq -e '.error' >/dev/null 2>&1; then
  echo "$LOGIN" | jq . >&2
  exit 1
fi
AUTH="$(echo "$LOGIN" | jq -c '.result')"
# auth é string JSON já com aspas
AUTH_RAW="$(echo "$LOGIN" | jq -r '.result')"

echo "[backup] A listar hosts / templates …"
HOST_IDS="$(zbx host.get '{"output":["hostid"],"filter":{}}' "$AUTH" | jq -c '[.result[].hostid]')"
TPL_IDS="$(zbx template.get '{"output":["templateid"],"filter":{}}' "$AUTH" | jq -c '[.result[].templateid]')"

HOST_COUNT="$(echo "$HOST_IDS" | jq 'length')"
TPL_COUNT="$(echo "$TPL_IDS" | jq 'length')"
echo "[backup] hosts=${HOST_COUNT} templates=${TPL_COUNT}"

export_cfg() {
  local name="$1"
  local options="$2"
  local resp
  resp="$(zbx configuration.export "{\"format\":\"json\",\"prettyprint\":true,\"options\":${options}}" "$AUTH")"
  if echo "$resp" | jq -e '.error' >/dev/null 2>&1; then
    echo "$resp" | jq . >&2
    return 1
  fi
  # result é string JSON escapada
  echo "$resp" | jq -r '.result' >"$OUT_DIR/${name}.json"
  echo "[backup] Escrito $OUT_DIR/${name}.json ($(wc -c <"$OUT_DIR/${name}.json") bytes)"
}

if [[ "$HOST_COUNT" -gt 0 ]]; then
  export_cfg hosts "{\"hosts\":${HOST_IDS}}"
else
  echo "[backup] Sem hosts para exportar (ok se ainda não criaste)."
  echo '{}' >"$OUT_DIR/hosts.json"
fi

# Exporta só templates cujo nome começa por LAB (triggers/templates teus).
# Se quiseres todos: ZABBIX_EXPORT_ALL_TEMPLATES=true
if [[ "${ZABBIX_EXPORT_ALL_TEMPLATES:-false}" == "true" ]]; then
  if [[ "$TPL_COUNT" -gt 0 ]]; then
    export_cfg templates "{\"templates\":${TPL_IDS}}"
  else
    echo '{}' >"$OUT_DIR/templates.json"
  fi
else
  LAB_TPL_IDS="$(zbx template.get '{"output":["templateid","name"]}' "$AUTH" | jq -c '[.result[] | select(.name|test("^LAB";"i")) | .templateid]')"
  LAB_N="$(echo "$LAB_TPL_IDS" | jq 'length')"
  echo "[backup] templates LAB=${LAB_N}"
  if [[ "$LAB_N" -gt 0 ]]; then
    export_cfg templates "{\"templates\":${LAB_TPL_IDS}}"
  else
    echo "[backup] Sem templates LAB:* — hosts.json já leva triggers ao nível do host."
    echo '{}' >"$OUT_DIR/templates.json"
  fi
fi

# metadata
cat >"$OUT_DIR/backup-meta.json" <<EOF
{
  "backed_up_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "zabbix_url": "${ZABBIX_URL}",
  "hosts": ${HOST_COUNT}
}
EOF

# logout best-effort
zbx user.logout "[]" "$AUTH" >/dev/null || true

echo "[backup] Feito. Agora:"
echo "  git add sre/zabbix/config-export && git commit -m \"chore: backup config Zabbix\""
echo "  cd terraform && terraform destroy"
