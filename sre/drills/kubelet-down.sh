#!/usr/bin/env bash
# Para kubelet (nó NotReady). SEMPRE faz restore.
# Uso: sudo bash kubelet-down.sh {start|restore}
set -euo pipefail

cmd="${1:-}"
case "$cmd" in
  start)
    echo "[drill] ATENÇÃO: nó vai ficar NotReady"
    systemctl stop kubelet
    systemctl status kubelet --no-pager || true
    echo "[drill] No CP: kubectl get nodes — Depois: sudo bash $0 restore"
    ;;
  restore)
    systemctl start kubelet
    systemctl enable kubelet
    systemctl status kubelet --no-pager
    echo "[drill] Valida: kubectl get nodes"
    ;;
  *) echo "Uso: sudo bash $0 {start|restore}" >&2; exit 1 ;;
esac
