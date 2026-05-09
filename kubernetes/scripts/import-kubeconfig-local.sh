#!/usr/bin/env bash
# Gera um kubeconfig na sua máquina com UM contexto de nome único.
# O nome do contexto coincide com o output Terraform kubeconfig_context_name (slug do project_name).
#
# Pré-requisitos: terraform, ssh, bash, kubectl, jq; SSH_KEY_PATH apontando para a .pem;
# no Terraform: expose_kubernetes_api_https = true (e apply) para a porta 6443 aceitar o seu IP.
#
# Uso (raiz do repositório) — ou atalho (caminho da .pem como argumento):
#   ./kubernetes/scripts/setup-kubectl-local.sh "/c/Users/.../chave.pem"
# Manual:
#   export SSH_KEY_PATH="/c/Users/.../sua-chave.pem"
#   ./kubernetes/scripts/import-kubeconfig-local.sh
#
# Depois (vários clusters no mesmo KUBECONFIG):
#   export KUBECONFIG="$HOME/.kube/config:$(pwd)/.kube-generated/<slug>.yaml"
#   kubectl config get-contexts
#   kubectl config use-context <slug>

set -euo pipefail

die() {
  [[ -n "${1:-}" ]] && printf '%s\n' "$1" >&2
  exit 1
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TF_DIR="$ROOT_DIR/terraform"
OUT_DIR="$ROOT_DIR/.kube-generated"

if [[ -z "${SSH_KEY_PATH:-}" ]]; then
  die "Defina SSH_KEY_PATH com o caminho da chave .pem (como em wait-for-cluster.sh)."
fi

if [[ "$SSH_KEY_PATH" =~ ^[A-Za-z]:\\ ]]; then
  if command -v cygpath >/dev/null 2>&1; then
    SSH_KEY_PATH="$(cygpath "$SSH_KEY_PATH")"
  fi
fi

[[ -f "$SSH_KEY_PATH" ]] || die "Chave não encontrada: $SSH_KEY_PATH"

for cmd in terraform ssh kubectl jq; do
  command -v "$cmd" >/dev/null 2>&1 || die "Comando necessário em falta: $cmd"
done

if ! terraform -chdir="$TF_DIR" output -raw kubeconfig_context_name >/dev/null 2>&1; then
  die "Não foi possível ler outputs do Terraform (correu apply neste diretório?)."
fi

CONTEXT_NAME="$(terraform -chdir="$TF_DIR" output -raw kubeconfig_context_name)"
CP_IP="$(terraform -chdir="$TF_DIR" output -raw control_plane_public_ip)"
API_EXPOSED="$(terraform -chdir="$TF_DIR" output -raw kubernetes_api_exposed_https 2>/dev/null || echo "unknown")"

[[ -n "$CONTEXT_NAME" && "$CONTEXT_NAME" != "null" ]] || die "kubeconfig_context_name inválido."
[[ -n "$CP_IP" && "$CP_IP" != "null" ]] || die "control_plane_public_ip inválido."

SSH_OPTS=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ConnectTimeout=20
)

RAW="$(mktemp)"
CA_FILE="$(mktemp)"
CC_FILE="$(mktemp)"
CK_FILE="$(mktemp)"
trap 'rm -f "$RAW" "$CA_FILE" "$CC_FILE" "$CK_FILE"' EXIT

ssh "${SSH_OPTS[@]}" "ubuntu@${CP_IP}" 'cat /home/ubuntu/.kube/config' >"$RAW"

if ! grep -q . "$RAW"; then
  die "Kubeconfig vazio no control-plane (bootstrap ainda a correr?)."
fi

CA_DATA="$(kubectl config view --kubeconfig="$RAW" --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' 2>/dev/null || true)"
if [[ -z "$CA_DATA" ]]; then
  die "Sem certificate-authority-data no kubeconfig remoto (formato inesperado)."
fi

CC_DATA="$(kubectl config view --kubeconfig="$RAW" --raw -o jsonpath='{.users[0].user.client-certificate-data}' 2>/dev/null || true)"
CK_DATA="$(kubectl config view --kubeconfig="$RAW" --raw -o jsonpath='{.users[0].user.client-key-data}' 2>/dev/null || true)"
if [[ -z "$CC_DATA" || -z "$CK_DATA" ]]; then
  die "Credenciais client-cert não encontradas no kubeconfig remoto."
fi

mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/${CONTEXT_NAME}.yaml"
rm -f "$OUT_FILE"

CLUSTER_NAME="${CONTEXT_NAME}"
USER_NAME="${CONTEXT_NAME}-admin"

# Algumas versões de kubectl não aceitam os flags "*-data" no set-cluster/set-credentials.
# Para compatibilidade, gravamos os blobs base64 em ficheiros temporários e usamos os flags de caminho.
printf '%s' "$CA_DATA" | base64 --decode >"$CA_FILE"
printf '%s' "$CC_DATA" | base64 --decode >"$CC_FILE"
printf '%s' "$CK_DATA" | base64 --decode >"$CK_FILE"

kubectl config set-cluster "$CLUSTER_NAME" \
  --kubeconfig="$OUT_FILE" \
  --server="https://${CP_IP}:6443" \
  --certificate-authority="$CA_FILE" \
  --embed-certs=true >/dev/null

kubectl config set-credentials "$USER_NAME" \
  --kubeconfig="$OUT_FILE" \
  --client-certificate="$CC_FILE" \
  --client-key="$CK_FILE" \
  --embed-certs=true >/dev/null

kubectl config set-context "$CONTEXT_NAME" \
  --kubeconfig="$OUT_FILE" \
  --cluster="$CLUSTER_NAME" \
  --user="$USER_NAME" >/dev/null

kubectl config use-context "$CONTEXT_NAME" --kubeconfig="$OUT_FILE" >/dev/null

echo "Kubeconfig escrito: $OUT_FILE"
echo "  contexto / cluster (recurso): $CONTEXT_NAME"
echo ""
if [[ "$API_EXPOSED" != "true" ]]; then
  echo "Aviso: expose_kubernetes_api_https não está true neste estado Terraform."
  echo "  kubectl da sua máquina para https://${CP_IP}:6443 tende a falhar até abrir 6443"
  echo "  (mesmos CIDRs que o SSH) e fazer terraform apply."
  echo ""
fi
echo "Juntar ao kubeconfig por defeito:"
echo "  export KUBECONFIG=\"\$HOME/.kube/config:${OUT_FILE}\""
echo "  kubectl config get-contexts"
echo "  kubectl config use-context ${CONTEXT_NAME}"
echo ""
