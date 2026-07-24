# Lab 02 — Namespaces e isolamento

Laboratório prático para CKA — **namespaces**, DNS entre namespaces e escopo de objetos.

| Modo | Arquivo | Tempo |
|------|---------|-------|
| **Guiado** | [README-guided.md](README-guided.md) | 45–60 min |
| **Speedrun** | [README-speedrun.md](README-speedrun.md) | 20–25 min |

Diagramas: [diagrams.html](diagrams.html).

## Cluster AWS (este repositório)

```bash
CKA_LABS=02-namespaces ./kubernetes/scripts/deploy-cka-labs.sh
```

Ou com lab 01: `CKA_LABS=01-objects,02-namespaces`. Depois: `cd ~/cka-labs/02-namespaces` no control-plane.

## Pré-requisitos

- Cluster com **CoreDNS** funcional
- Recomendado: concluir [Lab 01](../01-objects/README.md) antes

## Início rápido

```bash
cd ~/cka-labs/02-namespaces
kubectl apply -f manifests/namespaces.yaml
kubectl apply -f manifests/stack-vendas.yaml -f manifests/stack-infra.yaml
kubectl get pods -n lab-ns-vendas
kubectl get pods -n lab-ns-infra
```

## Limpeza

```bash
kubectl delete namespace lab-ns-vendas lab-ns-infra
```
