#!/usr/bin/env bash
# Porta down: mantém o serviço "instalado" mas sem escutar (lab).
# Usa crl-lab-app; start = stop do serviço; restore = start.
# Uso: sudo bash port-down.sh {start|restore}
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cmd="${1:-}"
case "$cmd" in
  start)
    sudo bash "$SCRIPT_DIR/service-down.sh" install
    echo "[drill] A derrubar a porta (stop crl-lab-app)"
    systemctl stop crl-lab-app
    ss -lntp | grep 8089 || echo "[drill] Porta 8089 em baixo (esperado)"
    echo "[drill] Depois: sudo bash $0 restore"
    ;;
  restore)
    sudo bash "$SCRIPT_DIR/service-down.sh" restore
    ;;
  *) echo "Uso: sudo bash $0 {start|restore}" >&2; exit 1 ;;
esac
