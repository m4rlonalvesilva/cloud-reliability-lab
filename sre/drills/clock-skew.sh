#!/usr/bin/env bash
# Para sync de tempo (lab). Uso: sudo bash clock-skew.sh {start|restore}
set -euo pipefail

cmd="${1:-}"
case "$cmd" in
  start)
    echo "[drill] A parar sincronização de relógio"
    systemctl stop systemd-timesyncd 2>/dev/null || true
    systemctl stop chrony 2>/dev/null || true
    systemctl stop chronyd 2>/dev/null || true
    timedatectl status || true
    echo "[drill] Depois: sudo bash $0 restore"
    ;;
  restore)
    echo "[drill] A restaurar sync de tempo"
    systemctl start systemd-timesyncd 2>/dev/null || true
    systemctl enable systemd-timesyncd 2>/dev/null || true
    systemctl start chrony 2>/dev/null || systemctl start chronyd 2>/dev/null || true
    timedatectl status || true
    ;;
  *) echo "Uso: sudo bash $0 {start|restore}" >&2; exit 1 ;;
esac
