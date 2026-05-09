#!/usr/bin/env bash
# Na raiz do repo: recebe o caminho da .pem como argumento, gera kubeconfig local e prepara KUBECONFIG.
# Pré-requisitos: terraform apply com expose_kubernetes_api_https = true; terraform, ssh, kubectl, jq.
# Uso (na raiz do repo, Git Bash):
#   ./kubernetes/scripts/setup-kubectl-local.sh "/c/Users/.../chave.pem"

set -euo pipefail

die() {
  [[ -n "${1:-}" ]] && printf '%s\n' "$1" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$ROOT_DIR/terraform"
OUT_DIR="$ROOT_DIR/.kube-generated"
IMPORT="$SCRIPT_DIR/import-kubeconfig-local.sh"
ACTIVATE="$OUT_DIR/activate-kubectl-local.sh"

[[ -n "${1:-}" ]] || die "Uso: $0 <caminho-da-chave.pem>   (ex.: /c/Users/VOCE/chave.pem)"
SSH_KEY_PATH="$1"
# remove aspas e espaços à volta
SSH_KEY_PATH="${SSH_KEY_PATH#"${SSH_KEY_PATH%%[![:space:]]*}"}"
SSH_KEY_PATH="${SSH_KEY_PATH%"${SSH_KEY_PATH##*[![:space:]]}"}"
SSH_KEY_PATH="${SSH_KEY_PATH//\"/}"
[[ -n "$SSH_KEY_PATH" ]] || die "Caminho da chave vazio."

if [[ "$SSH_KEY_PATH" =~ ^[A-Za-z]:\\ ]]; then
  if command -v cygpath >/dev/null 2>&1; then
    SSH_KEY_PATH="$(cygpath "$SSH_KEY_PATH")"
  fi
fi

[[ -f "$SSH_KEY_PATH" ]] || die "Ficheiro não encontrado: $SSH_KEY_PATH"

export SSH_KEY_PATH

if ! terraform -chdir="$TF_DIR" output -raw kubeconfig_context_name >/dev/null 2>&1; then
  echo "Terraform não lê outputs; a tentar init…" >&2
  terraform -chdir="$TF_DIR" init -upgrade >&2 || true
fi

bash "$IMPORT"

CONTEXT_NAME="$(terraform -chdir="$TF_DIR" output -raw kubeconfig_context_name)"
OUT_FILE="$OUT_DIR/${CONTEXT_NAME}.yaml"
[[ -f "$OUT_FILE" ]] || die "Kubeconfig esperado em falta: $OUT_FILE"

ABS_OUT="$(cd "$OUT_DIR" && pwd)/${CONTEXT_NAME}.yaml"

cat >"$ACTIVATE" <<EOF
#!/usr/bin/env bash
# Gerado por setup-kubectl-local.sh — não editar.
export KUBECONFIG="\${HOME}/.kube/config:${ABS_OUT}"
EOF
chmod +x "$ACTIVATE"

export KUBECONFIG="${HOME}/.kube/config:${ABS_OUT}"
kubectl config use-context "$CONTEXT_NAME" 2>/dev/null || true

echo ""
set +e
kubectl_out="$(kubectl get nodes -o wide 2>&1)"
kubectl_rc=$?
set -e
printf '%s\n' "$kubectl_out"
echo ""

if [[ "$kubectl_rc" -eq 0 ]]; then
  echo "SUCESSO — o cluster respondeu ao kubectl (teste feito dentro deste script)."
else
  echo "FALHA — kubectl não falou com o cluster (rede, 6443 ou bootstrap)." >&2
  exit 1
fi

echo ""
echo "O KUBECONFIG definido aqui não fica no Git Bash depois que o script acaba (processo filho)."
echo "Na mesma janela ou noutra, execute uma vez:"
echo "  source $(printf %q "$ACTIVATE")"
echo "Depois disso o kubectl funciona nessa janela."
