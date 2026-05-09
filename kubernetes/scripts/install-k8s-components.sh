#!/usr/bin/env bash
set -euo pipefail

echo "[k8s] Instalando kubeadm, kubelet e kubectl (canal estável mais recente)"

K8S_STABLE="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
K8S_MINOR="$(printf '%s' "$K8S_STABLE" | cut -d. -f1,2)"

echo "[k8s] Versão estável detectada: $K8S_STABLE"
echo "[k8s] Canal de pacotes: $K8S_MINOR"

sudo mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/$K8S_MINOR/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_MINOR/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

echo "[k8s] Componentes instalados"
