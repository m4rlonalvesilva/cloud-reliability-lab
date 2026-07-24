#!/usr/bin/env bash
# Funções partilhadas: Terraform outputs + SSH ao control-plane.
# Uso: source "$(dirname "${BASH_SOURCE[0]}")/lib/cluster-ssh.sh"  (a partir de kubernetes/scripts/)

cluster_ssh_die() {
  [[ -n "${1:-}" ]] && printf '%s\n' "$1" >&2
  if [[ -e /dev/tty ]]; then
    read -r -p "Enter para sair. " _ </dev/tty 2>/dev/null || true
  elif [[ -t 0 ]]; then
    read -r -p "Enter para sair. " _ || true
  fi
  exit 1
}

cluster_ssh_init() {
  if [[ -n "${CLUSTER_SSH_INITIALIZED:-}" ]]; then
    return 0
  fi

  CLUSTER_SSH_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
  CLUSTER_SSH_TF_DIR="$CLUSTER_SSH_ROOT_DIR/terraform"

  if [[ -z "${SSH_KEY_PATH:-}" ]]; then
    echo "Defina SSH_KEY_PATH com o caminho da chave .pem (não commitar)." >&2
    echo "Ex.: export SSH_KEY_PATH=\"/c/Users/SEU_USUARIO/caminho/cloud-reliability-lab-key.pem\"" >&2
    cluster_ssh_die
  fi

  if [[ "$SSH_KEY_PATH" =~ ^[A-Za-z]:\\ ]]; then
    if command -v cygpath >/dev/null 2>&1; then
      SSH_KEY_PATH="$(cygpath "$SSH_KEY_PATH")"
    fi
  fi

  if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "Chave não encontrada: $SSH_KEY_PATH" >&2
    cluster_ssh_die
  fi

  if [[ "$(uname -s)" == Linux ]]; then
    chmod go-rwx "$SSH_KEY_PATH" 2>/dev/null || true
  fi

  for cmd in terraform ssh; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Comando necessário em falta: $cmd" >&2
      cluster_ssh_die
    fi
  done

  if ! terraform -chdir="$CLUSTER_SSH_TF_DIR" output -json ec2_public_ips >/dev/null 2>&1; then
    echo "A correr terraform init -upgrade uma vez…" >&2
    terraform -chdir="$CLUSTER_SSH_TF_DIR" init -upgrade >&2 || true
  fi

  if ! terraform -chdir="$CLUSTER_SSH_TF_DIR" output -json ec2_public_ips >/dev/null 2>&1; then
    echo "Não foi possível ler terraform output (ec2_public_ips)." >&2
    cluster_ssh_die
  fi

  local ips_json
  ips_json="$(terraform -chdir="$CLUSTER_SSH_TF_DIR" output -json ec2_public_ips)"
  CLUSTER_SSH_CP_IP="$(echo "$ips_json" | jq -r '.[0]')"
  CLUSTER_SSH_EXPECTED_NODES="$(echo "$ips_json" | jq 'length')"

  if [[ -z "$CLUSTER_SSH_CP_IP" || "$CLUSTER_SSH_CP_IP" == "null" ]]; then
    echo "IP do control-plane inválido no output do Terraform." >&2
    cluster_ssh_die
  fi

  CLUSTER_SSH_OPTS=(
    -i "$SSH_KEY_PATH"
    -o StrictHostKeyChecking=accept-new
    -o UserKnownHostsFile=/dev/null
    -o LogLevel=ERROR
    -o ConnectTimeout=15
  )

  CLUSTER_SSH_INITIALIZED=1
}

cluster_ssh_run() {
  cluster_ssh_init
  ssh "${CLUSTER_SSH_OPTS[@]}" "ubuntu@${CLUSTER_SSH_CP_IP}" "$@"
}

cluster_ssh_scp() {
  cluster_ssh_init
  scp "${CLUSTER_SSH_OPTS[@]}" "$@"
}
