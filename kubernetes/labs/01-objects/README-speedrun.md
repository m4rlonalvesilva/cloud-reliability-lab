# Lab 01 — Objetos Kubernetes (speedrun)

**Tempo:** 20–25 min · **Teoria:** [Objetos](../1.%20Objetos%20e%20Gerenciamento%20de%20Estado%20no%20Kubernetes.md)

Versão rápida. Para explicação de cada flag, use o [modo guiado](README-guided.md).

## Checklist

| # | Comando | Em uma linha |
|---|---------|--------------|
| 1 | `kubectl apply -f namespace.yaml` | Cria o namespace `lab-objects-01` de forma declarativa. |
| 2 | Corrigir + `kubectl apply -f manifests/pod-broken.yaml` | Após corrigir nome/indentação, registra o Pod no API Server. |
| 3 | `kubectl get pod -n lab-objects-01 -l app=obj-lab` | Lista Pods do namespace com label `app=obj-lab`. |
| 4 | `kubectl get pod nginx-fixed -n lab-objects-01 -o jsonpath='{.status.phase}{"\n"}'` | Lê só `status.phase` (deve imprimir `Running`). |
| 5 | `kubectl annotate pod nginx-fixed -n lab-objects-01 study.cka/module=objects` | Grava annotation em `metadata` sem editar o YAML. |
| 6 | `kubectl describe pod nginx-fixed -n lab-objects-01` | Relatório + Events; cite um na saída. |

## Erros comuns em `pod-broken.yaml`

| Erro | Correção |
|------|----------|
| Falta `metadata.name` | `name: nginx-fixed` |
| Indentação de `spec.containers` | alinhar sob `spec:` |
| (opcional) falta `labels` | manter `app: obj-lab` |

## Gabarito mínimo (`pod-broken` corrigido)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-fixed
  namespace: lab-objects-01
  labels:
    app: obj-lab
spec:
  containers:
    - name: nginx
      image: nginx:1.25-alpine
```

## Desafio extra

```bash
kubectl apply -f manifests/pod-invalid-field.yaml --validate=strict
```

**O que testa:** API Server rejeita schema inválido (`container` → corrigir para `containers`).

## Limpeza

```bash
kubectl delete namespace lab-objects-01
```

**O que faz:** remove o namespace e **todos** os objetos dentro dele (Pods, etc.) em cascata.
