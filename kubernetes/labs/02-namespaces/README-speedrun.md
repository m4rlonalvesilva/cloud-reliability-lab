# Lab 02 — Namespaces (speedrun)

**Tempo:** 20–25 min · **Teoria:** [Namespaces](../2.%20Objetos%2C%20Estado%20e%20Isolamento%20com%20Namespaces%20no%20Kubernetes.md)

Versão rápida. Detalhes de cada flag: [modo guiado](README-guided.md).

## Checklist

| # | Comando | Em uma linha |
|---|---------|--------------|
| 1 | `kubectl apply -f manifests/namespaces.yaml` | Cria os namespaces do lab. |
| 2 | `kubectl apply -f manifests/stack-vendas.yaml -f manifests/stack-infra.yaml` | Dois stacks idênticos em namespaces diferentes. |
| 3 | `kubectl get pods -n lab-ns-vendas` e `kubectl get pods -n lab-ns-infra` | Mesmo nome `db`, escopos distintos — sem conflito. |
| 4 | `kubectl apply -f manifests/dns-test.yaml` + `kubectl wait --for=condition=Ready pod/dns-test -n lab-ns-vendas --timeout=90s` | Sobe cliente DNS e espera ficar Ready. |
| 5 | `kubectl exec -n lab-ns-vendas dns-test -- nslookup db` | Resolução curta no mesmo namespace. |
| 6 | `kubectl exec -n lab-ns-vendas dns-test -- nslookup db.lab-ns-infra.svc.cluster.local` | Resolução cross-namespace via FQDN. |
| 7 | `kubectl api-resources --namespaced=true \| head` | Confirma recursos com escopo de namespace. |
| 8 | `kubectl get nodes` | Recurso cluster-scoped (sem `-n`). |

## Desafio extra

```bash
kubectl apply -f manifests/namespace-invalid.yaml
```

**O que testa:** nome `lab_ns_invalid` viola RFC 1123 (underscore) — API deve rejeitar.

## Limpeza

```bash
kubectl delete namespace lab-ns-vendas lab-ns-infra
```

**O que faz:** remove os dois namespaces e todo objeto dentro deles.
