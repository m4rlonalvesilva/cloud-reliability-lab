# Runbook — Containerd parado

## Sintoma

- kubelet up mas pods não correm / ImagePull / CreateContainer errors  
- `systemctl status containerd` inactive  
- Runtime down  

## Impacto

Workloads param naquele nó. Severidade: **HIGH/CRITICAL**.

## Diagnóstico

```bash
sudo systemctl status containerd --no-pager
sudo journalctl -u containerd -n 50 --no-pager
sudo crictl info 2>/dev/null || true
kubectl get pods -A -o wide | head
```

## Mitigação / Resolução

```bash
sudo systemctl start containerd
sudo systemctl enable containerd
# kubelet pode precisar de restart se ficou inconsistente
sudo systemctl restart kubelet
kubectl get nodes
kubectl get pods -A | grep -v Running | head
```

## Validação

- [ ] containerd active  
- [ ] Node Ready  
- [ ] Pods a voltar  

## Lab

```bash
sudo bash drills/containerd-down.sh start
sudo bash drills/containerd-down.sh restore
```
