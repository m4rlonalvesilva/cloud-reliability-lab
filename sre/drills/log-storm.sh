#!/usr/bin/env bash
# Tempestade de logs em /var/tmp/crl-lab-logs (lab).
# Uso: bash log-storm.sh {start|restore}
set -euo pipefail
DIR=/var/tmp/crl-lab-logs
FLAG=/tmp/crl-drill-log-storm.pid
DURATION_SEC="${DRILL_LOG_SECONDS:-120}"
LINES_PER_SEC="${DRILL_LOG_RATE:-2000}"

cmd="${1:-}"
case "$cmd" in
  start)
    [[ -f "$FLAG" ]] && { echo "Já ativo"; exit 1; }
    mkdir -p "$DIR"
    echo "[drill] A gerar logs em $DIR/storm.log (~${DURATION_SEC}s)"
    (
      end=$((SECONDS + DURATION_SEC))
      while (( SECONDS < end )); do
        i=0
        while (( i < LINES_PER_SEC )); do
          echo "$(date -Is) ERROR lab-storm message=$i" >>"$DIR/storm.log"
          i=$((i + 1))
        done
        sleep 1
      done
      rm -f "$FLAG"
    ) &
    echo $! >"$FLAG"
    echo "[drill] PID $(cat "$FLAG"). Depois: bash $0 restore"
    ;;
  restore)
    if [[ -f "$FLAG" ]]; then
      kill "$(cat "$FLAG")" 2>/dev/null || true
      rm -f "$FLAG"
    fi
    rm -rf "$DIR"
    echo "[drill] Logs removidos. df -h /var/tmp:"
    df -h /var/tmp
    ;;
  *) echo "Uso: bash $0 {start|restore}" >&2; exit 1 ;;
esac
