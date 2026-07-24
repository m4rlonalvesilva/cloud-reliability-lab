#!/usr/bin/env bash
# Drill: CPU alta controlada (lab).
# Uso (no host):
#   bash cpu-high.sh start     # ~3 minutos ou até restore
#   bash cpu-high.sh restore
set -euo pipefail

FLAG=/tmp/crl-drill-cpu-high.pids
DURATION_SEC="${DRILL_CPU_SECONDS:-180}"

cmd="${1:-}"
case "$cmd" in
  start)
    if [[ -f "$FLAG" ]]; then
      echo "[drill] Já parece ativo ($FLAG). Usa restore primeiro." >&2
      exit 1
    fi
    echo "[drill] A gerar carga de CPU por até ${DURATION_SEC}s (2 workers 'yes')"
    : >"$FLAG"
    (
      yes >/dev/null & echo $! >>"$FLAG"
      yes >/dev/null & echo $! >>"$FLAG"
      sleep "$DURATION_SEC"
      if [[ -f "$FLAG" ]]; then
        while read -r pid; do kill "$pid" 2>/dev/null || true; done <"$FLAG"
        rm -f "$FLAG"
      fi
    ) &
    echo "[drill] PIDs em $FLAG. Monitoriza no Zabbix; depois: bash $0 restore"
    ;;
  restore)
    echo "[drill] A parar stress de CPU"
    if [[ -f "$FLAG" ]]; then
      while read -r pid; do kill "$pid" 2>/dev/null || true; done <"$FLAG"
      rm -f "$FLAG"
    fi
    pkill -f '^yes$' 2>/dev/null || true
    echo "[drill] Feito. Valida CPU a descer na UI."
    ;;
  *)
    echo "Uso: bash $0 {start|restore}" >&2
    exit 1
    ;;
esac
