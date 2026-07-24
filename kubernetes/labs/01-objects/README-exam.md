# Lab 01 — Simulado estilo prova CKA (objetos)

**Tempo total:** 40 min · **Ferramentas:** só o que existe na prova — `kubectl` (`k`), `vim`/`vi`, documentação oficial, **`yq`** se precisar. **Sem** Python/PyYAML.

**Formato:** igual ao exame performance-based da LF — enunciado, critério de correção, você resolve no terminal. **Não** abra o [modo guiado](README-guided.md) até terminar ou desistir.

---

## Regras (como na prova)

1. Leia **todas** as tarefas antes de começar (2–3 min).
2. Cada tarefa indica **namespace** e **host** — aqui tudo é no cluster do seu `kubeconfig` atual.
3. Valide com os comandos de verificação antes de avançar.
4. Pode usar `kubectl explain`, `kubernetes.io/docs` e bloco de notas (no exame real: PSI).
5. Gabarito: [solution-exam.md](solution-exam.md) — só depois de entregar.

**Limpeza final (obrigatória):** `kubectl delete namespace exam-cka-obj --ignore-not-found`

---

## Tarefa 1 — Namespace (5%)

Crie o namespace **`exam-cka-obj`** usando **apenas** `kubectl` (comando imperativo). Não use arquivo YAML.

**Verificação:**

```bash
kubectl get namespace exam-cka-obj
```

---

## Tarefa 2 — Pod via dry-run (15%)

No namespace **`exam-cka-obj`**, crie um Pod chamado **`web`** com:

- Imagem: `nginx:1.25-alpine`
- Label: `tier=web`
- Container port: `80` (campo `containerPort`)

**Restrições (estilo prova):**

- Gere o manifesto com `kubectl run` **ou** `kubectl create` usando `--dry-run=client -o yaml`.
- Edite o YAML gerado se necessário (namespace, labels, porta).
- Aplique com `kubectl apply -f` (arquivo temporário permitido).

**Não** use `kubectl run` sem dry-run para criar o Pod diretamente.

**Verificação:**

```bash
kubectl get pod web -n exam-cka-obj -o wide
kubectl get pod web -n exam-cka-obj -o jsonpath='{.metadata.labels.tier}{"\n"}'
```

Esperado: `Running`, label `web`.

---

## Tarefa 3 — Corrigir YAML quebrado (20%)

O arquivo `manifests/exam/pod-broken-exam.yaml` está **incorreto** e o Pod não pode ser criado como está.

Corrija o manifesto e aplique de forma que exista um Pod **`api-fix`** em **`exam-cka-obj`**, com label `app=api-fix`, em estado **`Running`**.

**Verificação:**

```bash
kubectl get pod api-fix -n exam-cka-obj
kubectl get pod api-fix -n exam-cka-obj -o jsonpath='{.status.phase}{"\n"}'
```

---

## Tarefa 4 — Metadados sem editar YAML (10%)

No Pod **`web`** (namespace `exam-cka-obj`), adicione a **annotation**:

`exam.cka/task=4`

Use apenas `kubectl` (sem reabrir o YAML da tarefa 2).

**Verificação:**

```bash
kubectl get pod web -n exam-cka-obj -o jsonpath='{.metadata.annotations.exam\.cka/task}{"\n"}'
```

---

## Tarefa 5 — `spec` vs `status` (15%)

Sem alterar o cluster, responda **no seu bloco de notas** (como na prova):

1. Qual campo do objeto Pod guarda a imagem desejada — `spec` ou `status`?
2. Qual campo indica se o Pod está `Running` — `spec` ou `status`?

Em seguida, prove no terminal com **um** comando `kubectl get` em formato YAML e cite o caminho exato do campo da fase (ex.: `status.phase`).

**Verificação (automática só da parte terminal):**

```bash
kubectl get pod web -n exam-cka-obj -o jsonpath='{.status.phase}{"\n"}'
```

---

## Tarefa 6 — Validação e schema (15%)

1. Tente aplicar `manifests/pod-invalid-field.yaml` no namespace **`exam-cka-obj`** com `--validate=strict` (ajuste o campo `namespace` no arquivo ou use redirecionamento, se souber).
2. Corrija o erro de schema, reaplique e deixe um Pod **`nginx-invalid`** `Running` nesse namespace.

**Verificação:**

```bash
kubectl get pod nginx-invalid -n exam-cka-obj
```

---

## Tarefa 7 — Declarativo após falha (20%)

1. Delete o Pod **`web`** (mantenha o namespace).
2. Recrie **`web`** com o **mesmo** `spec` da tarefa 2 usando **somente** `kubectl apply -f` e o arquivo YAML que você salvou (ou recrie o YAML com dry-run de novo).

**Verificação:**

```bash
kubectl get pod web -n exam-cka-obj
kubectl describe pod web -n exam-cka-obj | tail -5
```

Deve haver Events recentes de criação (`Scheduled`, `Started`, etc.).

---

## Critérios de “passou no simulado”

| Resultado | Significado |
|-----------|-------------|
| **≥ 80%** das verificações OK em ≤ 40 min | Pronto para misturar com labs de domínio |
| **60–79%** | Refaça tarefas falhas no [guiado](README-guided.md) |
| **< 60%** | Estude teoria + guiado antes do próximo simulado |

## Próximo simulado

[Lab 02 — Namespaces (modo exame)](../../2.%20Namespaces%20e%20Isolamento/lab/README-exam.md)
