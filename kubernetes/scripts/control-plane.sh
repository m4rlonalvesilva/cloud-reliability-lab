#!/usr/bin/env bash
set -euo pipefail

: "${SSM_JOIN_PARAMETER_NAME:?SSM_JOIN_PARAMETER_NAME não definido (user_data)}"
: "${AWS_DEFAULT_REGION:?AWS_DEFAULT_REGION não definido (user_data)}"

echo "[control-plane] Configurando control-plane e cluster"

MEM_MB="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)"
if (( MEM_MB < 1700 )); then
  echo "[control-plane] ERRO: memória insuficiente (${MEM_MB} MB). Use instance_type com pelo menos ~2 GiB (ex.: t3.small)."
  exit 1
fi

if [[ ! -f /etc/kubernetes/admin.conf ]]; then
  echo "[control-plane] kubeadm init"
  # SANs extra: acesso via IP publico/privado da EC2 e loopback (kubeconfig local / tuneis).
  IMDS_TOKEN="$(curl -fsSL -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || true)"
  meta() {
    curl -fsSL -H "X-aws-ec2-metadata-token: ${IMDS_TOKEN}" \
      "http://169.254.169.254/latest/meta-data/${1}" 2>/dev/null || true
  }
  PUBLIC_IP="$(meta public-ipv4)"
  LOCAL_IP="$(meta local-ipv4)"
  APISERVER_EXTRA_SANS="127.0.0.1,localhost"
  [[ -n "$PUBLIC_IP" ]] && APISERVER_EXTRA_SANS="${APISERVER_EXTRA_SANS},${PUBLIC_IP}"
  [[ -n "$LOCAL_IP" ]] && APISERVER_EXTRA_SANS="${APISERVER_EXTRA_SANS},${LOCAL_IP}"
  echo "[control-plane] apiserver-cert-extra-sans: ${APISERVER_EXTRA_SANS}"
  sudo kubeadm init --pod-network-cidr=192.168.0.0/16 \
    --apiserver-cert-extra-sans="${APISERVER_EXTRA_SANS}"
fi

# user_data corre como root; $HOME seria /root — kubeconfig tem de ficar para o utilizador ubuntu
UBUNTU_HOME="/home/ubuntu"
mkdir -p "$UBUNTU_HOME/.kube"
cp -f /etc/kubernetes/admin.conf "$UBUNTU_HOME/.kube/config"
chown ubuntu:ubuntu "$UBUNTU_HOME/.kube/config"

# O resto do script corre como root no cloud-init; kubectl precisa de kubeconfig explícito
export KUBECONFIG=/etc/kubernetes/admin.conf

JOIN_CMD="$(sudo kubeadm token create --print-join-command)"
echo "[control-plane] Publicando comando de join no SSM (${SSM_JOIN_PARAMETER_NAME})"
aws ssm put-parameter \
  --name "$SSM_JOIN_PARAMETER_NAME" \
  --description "kubeadm join (lab ${SSM_JOIN_PARAMETER_NAME})" \
  --value "$JOIN_CMD" \
  --type String \
  --overwrite \
  --region "$AWS_DEFAULT_REGION"

if ! kubectl get daemonset calico-node -n kube-system >/dev/null 2>&1; then
  echo "[control-plane] Instalando Calico (CNI)"
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml
fi

echo "[control-plane] Nós (worker pode ainda estar a juntar-se)"
kubectl get nodes -o wide || true
echo "[control-plane] Concluído"
