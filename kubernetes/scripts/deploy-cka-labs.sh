#!/usr/bin/env bash
# Publica no cluster os labs versionados em kubernetes/labs/ (cópia do kit CKA).
# Uso (na raiz do cloud-reliability-lab, com cluster Ready):
#   export SSH_KEY_PATH="/c/Users/.../sua-chave.pem"
#   ./kubernetes/scripts/deploy-cka-labs.sh
#
# Variáveis:
#   CKA_LABS           — ids em kubernetes/labs/, separados por vírgula (padrão: 01-objects)
#   CKA_LABS_DIR       — pasta local dos labs (padrão: kubernetes/labs no repo)
#   CKA_LAB_REMOTE_DIR — pasta no control-plane (padrão: ~/cka-labs)
#   CKA_SKIP_COPY      — se "true", não copia YAMLs (só kubectl apply do bootstrap)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/cluster-ssh.sh
source "$SCRIPT_DIR/lib/cluster-ssh.sh"

ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CKA_LABS_DIR="${CKA_LABS_DIR:-$ROOT_DIR/kubernetes/labs}"
CKA_LABS="${CKA_LABS:-01-objects}"
CKA_LAB_REMOTE_DIR="${CKA_LAB_REMOTE_DIR:-/home/ubuntu/cka-labs}"

declare -A LAB_BOOTSTRAP_MANIFESTS=(
  ["01-objects"]="namespace.yaml"
  ["02-namespaces"]="manifests/namespaces.yaml"
)

deploy_lab() {
  local lab_id="$1"
  local local_dir="${CKA_LABS_DIR}/${lab_id}"

  if [[ ! -d "$local_dir" ]]; then
    echo "Pasta do lab não encontrada: $local_dir" >&2
    echo "Labs disponíveis:" >&2
    ls -1 "$CKA_LABS_DIR" 2>/dev/null | grep -v README.md >&2 || true
    return 1
  fi

  local remote_dir="${CKA_LAB_REMOTE_DIR}/${lab_id}"
  echo "== Lab: $lab_id =="
  echo "   Origem:  $local_dir"
  echo "   Destino: ubuntu@${CLUSTER_SSH_CP_IP}:${remote_dir}"

  if [[ "${CKA_SKIP_COPY:-}" != "true" ]]; then
    cluster_ssh_run "mkdir -p '${remote_dir}'"
    cluster_ssh_scp -r "$local_dir/"* "ubuntu@${CLUSTER_SSH_CP_IP}:${remote_dir}/"
    echo "   Ficheiros copiados para o control-plane."
  fi

  local bootstrap="${LAB_BOOTSTRAP_MANIFESTS[$lab_id]:-}"
  if [[ -n "$bootstrap" ]]; then
    cluster_ssh_run "kubectl apply -f '${remote_dir}/${bootstrap}'"
    echo "   Bootstrap: ${bootstrap} aplicado."
  fi

  case "$lab_id" in
    01-objects)
      echo ""
      echo "   Namespace: lab-objects-01"
      echo "   Próximo passo: cd ${remote_dir} && kubectl apply -f manifests/pod-minimal.yaml"
      echo "   Guia: README-guided.md (nesta pasta no CP ou em kubernetes/labs/01-objects)"
      ;;
    02-namespaces)
      echo ""
      echo "   Namespaces: lab-ns-vendas, lab-ns-infra"
      echo "   Próximo passo: kubectl apply -f manifests/stack-vendas.yaml -f manifests/stack-infra.yaml"
      echo "   Guia: README-guided.md"
      ;;
  esac
  echo ""
}

main() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Comando necessário em falta: jq" >&2
    cluster_ssh_die
  fi

  if [[ ! -d "$CKA_LABS_DIR" ]]; then
    echo "Diretório de labs não encontrado: $CKA_LABS_DIR" >&2
    cluster_ssh_die
  fi

  cluster_ssh_init
  echo "== Publicar labs no control-plane ${CLUSTER_SSH_CP_IP} =="
  echo "   Origem local: ${CKA_LABS_DIR}"
  echo ""

  IFS=',' read -r -a lab_ids <<<"$CKA_LABS"
  for lab_id in "${lab_ids[@]}"; do
    lab_id="$(echo "$lab_id" | tr -d '[:space:]')"
    [[ -n "$lab_id" ]] || continue
    deploy_lab "$lab_id"
  done

  echo "=== Labs publicados ==="
  cluster_ssh_run kubectl get namespaces -l 'study.cka/module' 2>/dev/null || \
    cluster_ssh_run kubectl get ns -l 'study.cka/module' 2>/dev/null || true
}

main "$@"
