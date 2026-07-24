#!/usr/bin/env bash
# Para containerd. SEMPRE faz restore.
# Uso: sudo bash containerd-down.sh {start|restore}
set -euo pipefail

cmd="${1:-}"
case "$cmd" in
  start)
    echo "[drill] ATENÇÃO: runtime down — pods neste nó vão falhar"
    systemctl stop containerd
    systemctl status containerd --no-pager || true
    echo "[drill] Depois: sudo bash $0 restore"
    ;;
  restore)
    systemctl start containerd
    systemctl enable containerd
    systemctl restart kubelet
    systemctl status containerd --no-pager
    echo "[drill] Valida: kubectl get nodes; kubectl get pods -A"
    ;;
  *) echo "Uso: sudo bash $0 {start|restore}" >&2; exit 1 ;;
esac
