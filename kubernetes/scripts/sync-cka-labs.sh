#!/usr/bin/env bash
# Copia labs do projeto CKA (repositório separado) para kubernetes/labs/ deste repo.
# Uso (na raiz do cloud-reliability-lab):
#   ./kubernetes/scripts/sync-cka-labs.sh
#
# Variáveis:
#   CKA_SOURCE_ROOT — raiz do kit CKA (padrão: ../CKA)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CKA_SOURCE_ROOT="${CKA_SOURCE_ROOT:-$ROOT_DIR/../CKA}"
LABS_DST="${ROOT_DIR}/kubernetes/labs"

declare -A SYNC_MAP=(
  ["01-objects"]="fundaments/1. Objetos Kubernetes/lab"
  ["02-namespaces"]="fundaments/2. Namespaces e Isolamento/lab"
)

if [[ ! -d "$CKA_SOURCE_ROOT" ]]; then
  echo "Kit CKA não encontrado: $CKA_SOURCE_ROOT" >&2
  echo "Defina CKA_SOURCE_ROOT com a raiz do outro repositório." >&2
  exit 1
fi

echo "== Sincronizar labs CKA → cloud-reliability-lab =="
echo "   Origem: $CKA_SOURCE_ROOT"
echo "   Destino: $LABS_DST"
echo ""

for lab_id in "${!SYNC_MAP[@]}"; do
  src="${CKA_SOURCE_ROOT}/${SYNC_MAP[$lab_id]}"
  dst="${LABS_DST}/${lab_id}"
  if [[ ! -d "$src" ]]; then
    echo "Ignorado (origem ausente): $lab_id — $src" >&2
    continue
  fi
  mkdir -p "$dst"
  rsync -a --delete "${src}/" "${dst}/" 2>/dev/null || {
    rm -rf "${dst:?}"/*
    cp -r "${src}/." "${dst}/"
  }
  echo "   OK: $lab_id"
done

echo ""
echo "Concluído. Revise com git diff e faça commit neste repositório se quiser versionar."
