# Runbook — Kubelet parado (nó NotReady)

## Sintoma

- `kubectl get nodes` → NotReady  
- Pods deixam de ser agendados / ficam Unknown  
- Zabbix: se monitorares kubelet/systemd, serviço down  

## Impacto

Nó fora do cluster. Severidade: **HIGH/CRITICAL** conforme % de capacidade.

## Diagnóstico

```bash
# No control-plane:
kubectl get nodes -o wide
kubectl describe node <nome> | tail -40

# No nó afetado (SSH):
sudo systemctl status kubelet --no-pager
sudo journalctl -u kubelet -n 50 --no-pager
```

## Mitigação / Resolução

```bash
sudo systemctl start kubelet
sudo systemctl enable kubelet
sudo systemctl status kubelet --no-pager
kubectl get nodes
```

## Validação

- [ ] Node Ready  
- [ ] Pods a recuperar  
- [ ] Problem OK  

## Lab

**Atenção:** degrada o cluster de propósito. Faz sempre restore.

```bash
sudo bash drills/kubelet-down.sh start
sudo bash drills/kubelet-down.sh restore
```
