#!/usr/bin/env bash
set -euo pipefail

: "${SSM_JOIN_PARAMETER_NAME:?SSM_JOIN_PARAMETER_NAME não definido (user_data)}"
: "${AWS_DEFAULT_REGION:?AWS_DEFAULT_REGION não definido (user_data)}"

echo "[worker] Preparando join ao cluster"

if [[ -f /etc/kubernetes/kubelet.conf ]]; then
  echo "[worker] Já no cluster (kubelet.conf existe)"
  exit 0
fi

DEADLINE=$((SECONDS + 3600))
while (( SECONDS < DEADLINE )); do
  if JOIN_CMD="$(aws ssm get-parameter \
    --name "$SSM_JOIN_PARAMETER_NAME" \
    --query Parameter.Value \
    --output text \
    --region "$AWS_DEFAULT_REGION" 2>/dev/null)"; then
    if [[ "$JOIN_CMD" == kubeadm\ join* ]]; then
      echo "[worker] Comando de join obtido; a executar kubeadm join"
      if sudo bash -c "$JOIN_CMD"; then
        echo "[worker] Join concluído"
        exit 0
      fi
      echo "[worker] Join falhou (ex.: comando antigo no SSM ou API ainda indisponível). Nova tentativa em 45s..."
      sleep 45
      continue
    fi
  fi
  echo "[worker] À espera do control-plane publicar o join no SSM (30s)..."
  sleep 30
done

echo "[worker] ERRO: timeout à espera do parâmetro SSM do join"
exit 1
