#!/usr/bin/env bash
# Aguarda o cluster ficar utilizável após terraform apply (SSH no control-plane + kubectl).
# Uso (na raiz do repositório):
#   export SSH_KEY_PATH="/c/Users/.../sua-chave.pem"
#   ./kubernetes/scripts/wait-for-cluster.sh
#
# Requisitos: terraform, ssh, bash, jq (Windows: winget install jqlang.jq — README seção 1)

set -euo pipefail

# Em Git Bash aberto pelo Explorador (duplo-clique) ou em certos atalhos, a janela
# fecha ao fim do processo — use uma sessão Git Bash já aberta na raiz do repo.

die() {
  [[ -n "${1:-}" ]] && printf '%s\n' "$1" >&2
  # Dar tempo de ler o erro antes da janela fechar (Windows / mintty).
  if [[ -e /dev/tty ]]; then
    read -r -p "Enter para sair. " _ </dev/tty 2>/dev/null || true
  elif [[ -t 0 ]]; then
    read -r -p "Enter para sair. " _ || true
  fi
  exit 1
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TF_DIR="$ROOT_DIR/terraform"

INTERVAL_SEC="${WAIT_INTERVAL_SEC:-20}"
MAX_WAIT_SEC="${WAIT_MAX_SEC:-3600}"

if [[ -z "${SSH_KEY_PATH:-}" ]]; then
  echo "Defina SSH_KEY_PATH com o caminho da chave .pem (não commitar)." >&2
  echo "Ex.: export SSH_KEY_PATH=\"/c/Users/SEU_USUARIO/caminho/cloud-reliability-lab-key.pem\"" >&2
  die
fi

if [[ "$SSH_KEY_PATH" =~ ^[A-Za-z]:\\ ]]; then
  if command -v cygpath >/dev/null 2>&1; then
    SSH_KEY_PATH="$(cygpath "$SSH_KEY_PATH")"
  fi
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  echo "Chave não encontrada: $SSH_KEY_PATH" >&2
  die
fi

# Linux: OpenSSH exige chave sem permissões "demasiado abertas".
# Em ficheiros sob /mnt/c/ (NTFS) o chmod pode não surtir efeito — nesse caso copie a .pem para $HOME e chmod 600.
if [[ "$(uname -s)" == Linux ]]; then
  chmod go-rwx "$SSH_KEY_PATH" 2>/dev/null || true
fi

for cmd in terraform ssh jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Comando necessário em falta: $cmd" >&2
    [[ "$cmd" == "jq" ]] && echo "Instale jq: winget install jqlang.jq (README seção 1)." >&2
    die
  fi
done

if ! terraform -chdir="$TF_DIR" output -json ec2_public_ips >/dev/null 2>&1; then
  echo "Terraform não leu ec2_public_ips (típico: apply noutro ambiente/OS e binários .terraform só para outra plataforma)." >&2
  echo "A correr terraform init -upgrade uma vez…" >&2
  terraform -chdir="$TF_DIR" init -upgrade >&2 || true
fi

if ! terraform -chdir="$TF_DIR" output -json ec2_public_ips >/dev/null 2>&1; then
  echo "Não foi possível ler terraform output (ec2_public_ips)." >&2
  echo "Detalhe do Terraform:" >&2
  terraform -chdir="$TF_DIR" output -json ec2_public_ips 2>&1 | sed 's/^/  /' >&2 || true
  echo "" >&2
  echo "Dicas: confirme que existe terraform/terraform.tfstate após um apply." >&2
  echo "Se o estado existe, rode manualmente:" >&2
  echo "  terraform -chdir=\"$TF_DIR\" init -upgrade" >&2
  echo "  terraform -chdir=\"$TF_DIR\" output -json ec2_public_ips" >&2
  die
fi

IPS_JSON="$(terraform -chdir="$TF_DIR" output -json ec2_public_ips)"
CP_IP="$(echo "$IPS_JSON" | jq -r '.[0]')"
EXPECTED_NODES="$(echo "$IPS_JSON" | jq 'length')"

if [[ -z "$CP_IP" || "$CP_IP" == "null" ]]; then
  echo "IP do control-plane inválido no output do Terraform." >&2
  exit 1
fi

SSH_OPTS=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ConnectTimeout=15
)

run_ssh() {
  ssh "${SSH_OPTS[@]}" "ubuntu@${CP_IP}" "$@"
}

echo "A testar SSH ao control-plane ${CP_IP}…" >&2
set +e
_ssh_test_out="$(run_ssh 'echo ssh_ok' 2>&1)"
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
  # Imprime só um número (0 se ainda não há kubeconfig ou kubectl falha)
  run_ssh 'bash -s' <<'REMOTE'
set -u
if [[ ! -f /home/ubuntu/.kube/config ]]; then
  echo 0
  exit 0
fi
kubectl get nodes --no-headers 2>/dev/null | awk '$2=="Ready"{n++} END{print n+0}' || echo 0
REMOTE
}

echo "== Aguardando cluster (control-plane ${CP_IP}, ${EXPECTED_NODES} nó(s) esperado(s)) =="
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
    echo "[$ts] Nós Ready: ${count}/${EXPECTED_NODES}"
    last_count=$count
  else
    echo "[$ts] Nós Ready: ${count}/${EXPECTED_NODES} (sem alteração)"
  fi

  if (( count >= EXPECTED_NODES )); then
    echo ""
    echo "=== Cluster funcional — ${count} nó(s) Ready ==="
    run_ssh kubectl get nodes -o wide
    echo ""
    run_ssh kubectl get pods -A
    printf '\a'
    exit 0
  fi

  sleep "$INTERVAL_SEC"
done

echo "" >&2
echo "Timeout após ${MAX_WAIT_SEC}s. Veja no control-plane: sudo tail -100 /var/log/k8s-bootstrap.log" >&2
exit 1
