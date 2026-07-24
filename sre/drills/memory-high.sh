#!/usr/bin/env bash
# Drill: memória alta controlada (lab).
# Uso (no host):
#   bash memory-high.sh start
#   bash memory-high.sh restore
set -euo pipefail

FLAG=/tmp/crl-drill-memory-high.pid
MEM_MB="${DRILL_MEM_MB:-400}"
DURATION_SEC="${DRILL_MEM_SECONDS:-180}"

cmd="${1:-}"
case "$cmd" in
  start)
    if [[ -f "$FLAG" ]]; then
      echo "[drill] Já parece ativo ($FLAG). Usa restore primeiro." >&2
      exit 1
    fi
    if ! command -v python3 >/dev/null 2>&1; then
      echo "[drill] Precisas de python3 neste host." >&2
      exit 1
    fi
    echo "[drill] A consumir ~${MEM_MB}MiB por até ${DURATION_SEC}s"
    python3 -c "
import os, time
os.environ['CRL'] = '1'
open('${FLAG}', 'w').write(str(os.getpid()))
blob = bytearray(${MEM_MB} * 1024 * 1024)
time.sleep(${DURATION_SEC})
" &
    echo $! >"$FLAG"
    echo "[drill] PID $(cat "$FLAG"). Monitoriza no Zabbix; depois: bash $0 restore"
    ;;
  restore)
    echo "[drill] A libertar memória do drill"
    if [[ -f "$FLAG" ]]; then
      kill "$(cat "$FLAG")" 2>/dev/null || true
      rm -f "$FLAG"
    fi
    echo "[drill] Feito. Valida free -h e UI."
    ;;
  *)
    echo "Uso: bash $0 {start|restore}" >&2
    exit 1
    ;;
esac
