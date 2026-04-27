#!/usr/bin/env bash
set -euo pipefail

ip="$(curl -fsS https://api.ipify.org)"

if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  printf '%s/32\n' "$ip"
else
  echo "Resposta inesperada ao consultar IP publico: $ip" >&2
  exit 1
fi
