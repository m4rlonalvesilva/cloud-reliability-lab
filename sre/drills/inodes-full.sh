#!/usr/bin/env bash
# Esgota inodes com muitos ficheiros pequenos (lab).
# Uso: bash inodes-full.sh {start|restore}
set -euo pipefail
DIR=/var/tmp/crl-lab-inodes
COUNT="${DRILL_INODE_COUNT:-50000}"

cmd="${1:-}"
case "$cmd" in
  start)
    echo "[drill] A criar ${COUNT} ficheiros em $DIR"
    mkdir -p "$DIR"
    # batches para não demorar eternamente em shells lentos
    i=0
    while (( i < COUNT )); do
      touch "$DIR/f-$i"
      i=$((i + 1))
      if (( i % 5000 == 0 )); then echo "[drill] $i..."; fi
    done
    df -hi /var/tmp
    echo "[drill] Depois: bash $0 restore"
    ;;
  restore)
    echo "[drill] A apagar $DIR"
    rm -rf "$DIR"
    df -hi /var/tmp
    ;;
  *) echo "Uso: bash $0 {start|restore}" >&2; exit 1 ;;
esac
