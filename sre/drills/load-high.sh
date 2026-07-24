#!/usr/bin/env bash
# Load alta: muitos processos em espera/CPU (lab).
# Uso: bash load-high.sh {start|restore}
set -euo pipefail
FLAG=/tmp/crl-drill-load.pids
N="${DRILL_LOAD_PROCS:-32}"
DURATION_SEC="${DRILL_LOAD_SECONDS:-180}"

cmd="${1:-}"
case "$cmd" in
  start)
    [[ -f "$FLAG" ]] && { echo "Já ativo"; exit 1; }
    echo "[drill] A lançar ${N} workers (load) por ~${DURATION_SEC}s"
    : >"$FLAG"
    (
      for _ in $(seq 1 "$N"); do
        nice -n 19 bash -c 'while true; do :; done' &
        echo $! >>"$FLAG"
      done
      sleep "$DURATION_SEC"
      if [[ -f "$FLAG" ]]; then
        while read -r pid; do kill "$pid" 2>/dev/null || true; done <"$FLAG"
        rm -f "$FLAG"
      fi
    ) &
    echo "[drill] uptime:; uptime"
    echo "[drill] Depois: bash $0 restore"
    ;;
  restore)
    if [[ -f "$FLAG" ]]; then
      while read -r pid; do kill "$pid" 2>/dev/null || true; done <"$FLAG"
      rm -f "$FLAG"
    fi
    pkill -f 'while true; do :; done' 2>/dev/null || true
    echo "[drill] Load a descer — uptime:"; uptime
    ;;
  *) echo "Uso: bash $0 {start|restore}" >&2; exit 1 ;;
esac
