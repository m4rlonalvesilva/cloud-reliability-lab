#!/usr/bin/env bash
# Drill: parar / restaurar zabbix-agent2 (lab).
# Uso (no host, com sudo):
#   sudo bash agent-down.sh start
#   sudo bash agent-down.sh restore
set -euo pipefail

cmd="${1:-}"
case "$cmd" in
  start)
    echo "[drill] A parar zabbix-agent2 (simula agent fora)"
    systemctl stop zabbix-agent2
    systemctl status zabbix-agent2 --no-pager || true
    echo "[drill] Espera 1–3 min e vê Problems / host vermelho na UI."
    echo "[drill] Depois: sudo bash $0 restore"
    ;;
  restore)
    echo "[drill] A restaurar zabbix-agent2"
    systemctl start zabbix-agent2
    systemctl enable zabbix-agent2
    systemctl status zabbix-agent2 --no-pager
    echo "[drill] Valida agent verde na UI."
    ;;
  *)
    echo "Uso: sudo bash $0 {start|restore}" >&2
    exit 1
    ;;
esac
