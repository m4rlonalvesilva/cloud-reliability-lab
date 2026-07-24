# Lab 01 — Objetos Kubernetes

Laboratório prático para CKA — **objetos e gerenciamento de estado** (Pod, `apiVersion`, `spec` vs `status`).

| Modo | Arquivo | Tempo |
|------|---------|-------|
| **Guiado (3 trilhas)** | [README-guided.md](README-guided.md) — Trilha 1 → 2 → 3 | 20–60 min |
| **Speedrun** | [README-speedrun.md](README-speedrun.md) | 20–25 min |

Diagramas: [diagrams.html](diagrams.html) no navegador.

## Cluster AWS (este repositório)

Com `terraform apply` e `./kubernetes/scripts/wait-for-cluster.sh` na raiz do **cloud-reliability-lab**:

1. O namespace `lab-objects-01` é criado automaticamente.
2. Estes ficheiros ficam em `~/cka-labs/01-objects` no control-plane (SSH).
3. Abra [README-guided.md](README-guided.md) → **Trilha 1** (ou Bloco B1 se o namespace já existir).

Detalhes: [../README.md](../README.md).

## Pré-requisitos

- Cluster com `kubectl` configurado
- Conteúdo teórico no **projeto CKA** (repositório de estudo separado)

## Início rápido (no control-plane ou com kubeconfig local)

```bash
cd ~/cka-labs/01-objects   # após deploy; ou kubernetes/labs/01-objects neste repo
kubectl apply -f namespace.yaml
kubectl apply -f manifests/pod-minimal.yaml
kubectl get pods -n lab-objects-01
```

## Manifestos

| Arquivo | Uso |
|---------|-----|
| `manifests/pod-minimal.yaml` | Referência correta |
| `manifests/pod-incomplete.yaml` | Completar `image` |
| `manifests/pod-invalid-field.yaml` | Exercício `--validate=strict` |
| `manifests/pod-wrong-apiversion.yaml` | Corrigir `apiVersion` |
| `manifests/pod-broken.yaml` | Corrigir YAML (speedrun) |

## Limpeza

```bash
kubectl delete namespace lab-objects-01
```
