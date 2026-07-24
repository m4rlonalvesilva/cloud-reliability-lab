# Gabarito — Lab 01 simulado (exame)

> Abra só depois de concluir ou esgotar o tempo.

## Tarefa 1

```bash
kubectl create namespace exam-cka-obj
```

## Tarefa 2

```bash
kubectl run web -n exam-cka-obj --image=nginx:1.25-alpine --dry-run=client -o yaml > /tmp/web.yaml
```

Editar `/tmp/web.yaml`: confirmar `metadata.namespace`, adicionar `metadata.labels.tier: web` e `containers[0].ports: [{containerPort: 80}]`.

```bash
kubectl apply -f /tmp/web.yaml
```

## Tarefa 3

Correções em `manifests/exam/pod-broken-exam.yaml`:

- `metadata.name: api-fix`
- indentar `containers` sob `spec`

```bash
kubectl apply -f manifests/exam/pod-broken-exam.yaml
```

## Tarefa 4

```bash
kubectl annotate pod web -n exam-cka-obj exam.cka/task=4
```

## Tarefa 5 (notas)

1. Imagem desejada → **`spec`** (`spec.containers[].image`)
2. Fase Running → **`status`** (`status.phase`)

```bash
kubectl get pod web -n exam-cka-obj -o yaml
# ou
kubectl get pod web -n exam-cka-obj -o jsonpath='{.status.phase}{"\n"}'
```

## Tarefa 6

Ajustar namespace no YAML inválido e trocar `container:` por `containers:`.

```bash
# após editar pod-invalid-field.yaml (namespace + containers)
kubectl apply -f manifests/pod-invalid-field.yaml --validate=strict
```

## Tarefa 7

```bash
kubectl delete pod web -n exam-cka-obj
kubectl apply -f /tmp/web.yaml
```

## Limpeza

```bash
kubectl delete namespace exam-cka-obj
```
