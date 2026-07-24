#!/usr/bin/env bash
# Enche disco de forma limitada em /var/tmp/crl-lab-fill (lab).
# Uso: bash disk-full.sh {start|restore}
set -euo pipefail
DIR=/var/tmp/crl-lab-fill
FILE="$DIR/fill.bin"
# Usa no máx. 70% do espaço livre, teto 2G (override: DRILL_DISK_MB)
cmd="${1:-}"

free_kb="$(df -Pk /var/tmp | awk 'NR==2{print $4}')"
max_mb=$(( free_kb / 1024 * 70 / 100 ))
(( max_mb > 2048 )) && max_mb=2048
(( max_mb < 64 )) && max_mb=64
MB="${DRILL_DISK_MB:-$max_mb}"

case "$cmd" in
  start)
    echo "[drill] A criar ~${MB}MiB em $FILE (espaço livre limitado)"
    mkdir -p "$DIR"
    dd if=/dev/zero of="$FILE" bs=1M count="$MB" status=progress
    df -h /var/tmp
    echo "[drill] Depois: bash $0 restore"
    ;;
  restore)
    echo "[drill] A limpar $DIR"
    rm -rf "$DIR"
    df -h /var/tmp
    ;;
  *) echo "Uso: bash $0 {start|restore}" >&2; exit 1 ;;
esac
