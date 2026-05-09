#!/usr/bin/env bash
set -euo pipefail

echo "[common] Preparando base do sistema para Kubernetes"

sudo swapoff -a
sudo sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab

cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf >/dev/null
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf >/dev/null
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

echo "[common] Instalando containerd"
sudo apt-get update -y
sudo apt-get install -y containerd ca-certificates curl gnupg awscli

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl restart containerd

echo "[common] Base pronta"
