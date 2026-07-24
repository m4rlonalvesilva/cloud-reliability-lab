#!/usr/bin/env bash
# Aguarda o cluster ficar utilizável após terraform apply (SSH no control-plane + kubectl).
# Uso (na raiz do repositório):
#   export SSH_KEY_PATH="/c/Users/.../sua-chave.pem"
#   ./kubernetes/scripts/wait-for-cluster.sh
#
# Requisitos: terraform, ssh, bash, jq (Windows: winget install jqlang.jq — README seção 1)
#
# Após todos os nós Ready, por padrão publica kubernetes/labs/. Desative com:
#   CKA_DEPLOY_LABS=false ./kubernetes/scripts/wait-for-cluster.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/cluster-ssh.sh
source "$SCRIPT_DIR/lib/cluster-ssh.sh"

die() {
  cluster_ssh_die "$@"
}

INTERVAL_SEC="${WAIT_INTERVAL_SEC:-20}"
MAX_WAIT_SEC="${WAIT_MAX_SEC:-3600}"

for cmd in jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Comando necessário em falta: $cmd" >&2
    [[ "$cmd" == "jq" ]] && echo "Instale jq: winget install jqlang.jq (README seção 1)." >&2
    die
  fi
done

cluster_ssh_init

echo "A testar SSH ao control-plane ${CLUSTER_SSH_CP_IP}…" >&2
set +e
_ssh_test_out="$(cluster_ssh_run 'echo ssh_ok' 2>&1)"
_ssh_test_rc=$?
set -e
_ssh_test_out="${_ssh_test_out//$'\r'/}"
_ssh_test_trim="$(printf '%s' "$_ssh_test_out" | tr -d '[:space:]')"
if [[ "$_ssh_test_rc" -ne 0 ]] || [[ "$_ssh_test_trim" != "ssh_ok" ]]; then
  echo "ERRO: SSH ao control-plane falhou (o wait ficaria sempre em 0/2)." >&2
  printf '%s\n' "$_ssh_test_out" >&2
  echo "" >&2
  echo "Dica (chave em /mnt/... ou NTFS: permissões podem falhar no OpenSSH): copie para \$HOME e restrinja:" >&2
  echo "  cp \"\$SSH_KEY_PATH\" \"\$HOME/lab-key.pem\" && chmod 600 \"\$HOME/lab-key.pem\"" >&2
  echo "  export SSH_KEY_PATH=\"\$HOME/lab-key.pem\"" >&2
  echo "  ./kubernetes/scripts/wait-for-cluster.sh" >&2
  die
fi

count_ready_nodes() {
  cluster_ssh_run 'bash -s' <<'REMOTE'
set -u
if [[ ! -f /home/ubuntu/.kube/config ]]; then
  echo 0
  exit 0
fi
kubectl get nodes --no-headers 2>/dev/null | awk '$2=="Ready"{n++} END{print n+0}' || echo 0
REMOTE
}

echo "== Aguardando cluster (control-plane ${CLUSTER_SSH_CP_IP}, ${CLUSTER_SSH_EXPECTED_NODES} nó(s) esperado(s)) =="
echo "   Intervalo: ${INTERVAL_SEC}s | Máximo: ${MAX_WAIT_SEC}s (ajuste WAIT_INTERVAL_SEC / WAIT_MAX_SEC)"
echo ""

deadline=$((SECONDS + MAX_WAIT_SEC))
last_count=-1

while (( SECONDS < deadline )); do
  ts="$(date '+%H:%M:%S')"
  set +e
  count="$(count_ready_nodes 2>/dev/null | tail -n 1 | tr -d '[:space:]')"
  set -e
  [[ "$count" =~ ^[0-9]+$ ]] || count=0

  if (( count != last_count )); then
    echo "[$ts] Nós Ready: ${count}/${CLUSTER_SSH_EXPECTED_NODES}"
    last_count=$count
  else
    echo "[$ts] Nós Ready: ${count}/${CLUSTER_SSH_EXPECTED_NODES} (sem alteração)"
  fi

  if (( count >= CLUSTER_SSH_EXPECTED_NODES )); then
    echo ""
    echo "=== Cluster funcional — ${count} nó(s) Ready ==="
    cluster_ssh_run kubectl get nodes -o wide
    echo ""
    cluster_ssh_run kubectl get pods -A
    echo ""

    _deploy="${CKA_DEPLOY_LABS:-true}"
    if [[ "$_deploy" != "false" && "$_deploy" != "0" ]]; then
      "$SCRIPT_DIR/deploy-cka-labs.sh"
    else
      echo "CKA_DEPLOY_LABS=false — labs CKA não publicados automaticamente."
      echo "Para publicar depois: ./kubernetes/scripts/deploy-cka-labs.sh"
    fi

    printf '\a'
    exit 0
  fi

  sleep "$INTERVAL_SEC"
done

echo "" >&2
echo "Timeout após ${MAX_WAIT_SEC}s. Veja no control-plane: sudo tail -100 /var/log/k8s-bootstrap.log" >&2
exit 1
