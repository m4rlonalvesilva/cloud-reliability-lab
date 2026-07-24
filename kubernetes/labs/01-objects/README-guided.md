# Lab 01 — Objetos Kubernetes (modo guiado)

**Tempo:** 45–60 min  
**Docs oficiais:** [Kubernetes objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) · [Manage objects](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/)

## O que você vai aprender

Em um cluster real, com **Pods** (sem Deployment):

1. Anatomia do manifesto: `apiVersion`, `kind`, `metadata`, `spec`
2. Diferença **`spec`** (o que você pede) vs **`status`** (o que o cluster reporta)
3. Comandos da prova: `apply`, `explain`, `get -o yaml`, `describe`, `diff`, validação `--validate=strict`

---

## Índice das trilhas (onde clicar no guia)

| Trilha | Nível | Tempo ~ | Vá para |
|--------|--------|---------|---------|
| **1** | Essencial (fundamentos) | 20–30 min | [Trilha 1](#trilha-1--essencial-fundamentos) → Blocos A, B, D |
| **2** | Intermediária | 20–30 min | [Trilha 2](#trilha-2--intermediária) → Blocos C, E |
| **3** | Nível prova | 10–15 min | [Trilha 3](#trilha-3--nível-prova) → Bloco F |

**Ordem no documento:** Trilha 1 (A → B → D) → Trilha 2 (C → E) → Trilha 3 (F).  
Pode **parar** ao final de qualquer trilha.

---

## Antes de começar (obrigatório)

### Onde rodar os comandos

Escolha **uma** opção e use-a em **todos** os passos.

| Opção | Como entrar na pasta do lab |
|--------|---------------------------|
| **A — SSH no control-plane** (recomendado) | `ssh -i "$SSH_KEY_PATH" ubuntu@<IP_CP>` depois `cd ~/cka-labs/01-objects` |
| **B — kubectl no seu PC** | `cd cloud-reliability-lab/kubernetes/labs/01-objects` com kubeconfig configurado ([README do projeto](../../../README.md#apendice-a-kubectl-no-seu-computador)) |

IP do control-plane: `cluster-lab.generated.txt` na raiz do repo ou `terraform output control_plane_public_ip`.

### O que o `wait-for-cluster` já fez

Se você rodou `./kubernetes/scripts/wait-for-cluster.sh` com sucesso:

- Namespace **`lab-objects-01`** já existe
- Ficheiros do lab estão em **`~/cka-labs/01-objects`** (opção A)

Confirme:

```bash
kubectl get namespace lab-objects-01
pwd    # deve ser a pasta do lab (contém namespace.yaml e manifests/)
```

| Resultado | O que fazer no passo A1 |
|-----------|-------------------------|
| Namespace existe | Pode **pular** o A1 ou repetir — verá `configured`, não `created` |
| `NotFound` | Execute o A1 normalmente |

### Estrutura dos passos

Cada passo segue sempre:

1. **Comando** — copie e execute  
2. **Resultado esperado** — compare com a sua saída  
3. **Por quê** — uma frase para fixar na prova  

### Editar YAML: editor ou linha de comando

Nos passos que pedem corrigir ficheiros, use **uma** opção:

| Opção | Quando usar |
|--------|-------------|
| **Comandos abaixo (`sed`)** | SSH sem editor, script rápido, reproduzível |
| **`nano` / `vim`** | Prova CKA (enunciado pede editar ficheiro) ou revisar o YAML à mão |

Todos os comandos `sed` assumem que você está em `~/cka-labs/01-objects` (ou `kubernetes/labs/01-objects` no PC).

---

## Mapa do lab (por trilha)

| Trilha | Blocos | Tema |
|--------|--------|------|
| **1** | A, B, D | API, Pod + `spec`/`status`, Events |
| **2** | C, E | Corrigir YAML, `diff`, `--validate=strict` |
| **3** | F | `dry-run`, annotation, `jsonpath` |

Diagrama interativo: [diagrams.html](diagrams.html) · ASCII no Bloco A.

---

## Ideia central (leia uma vez)

```text
  Você escreve          Cluster executa e reporta
  ───────────          ──────────────────────────
  spec (desejado)  →   controllers + kubelet  →  status (observado)

  kubectl apply envia o spec; você NÃO edita status à mão.
```

---

# Trilha 1 — Essencial (fundamentos)

**Objetivo:** criar um Pod e explicar `spec` vs `status`.  
**Checklist ao terminar:** namespace existe · `nginx-obj` Running · `describe` com Events · você localiza `spec` e `status` no `get -o yaml`.

---

## Bloco A — Descoberta da API

### Passo A1 — Namespace do lab

```bash
kubectl apply -f namespace.yaml
```

**Resultado esperado:** `namespace/lab-objects-01 created` ou `configured`.

**Por quê:** Namespace isola os objetos deste exercício do resto do cluster (`default`, `kube-system`, etc.).

---

### Passo A2 — Qual `apiVersion` o Pod usa?

```bash
kubectl api-resources | grep -E 'NAME|pods'
```

**Resultado esperado:** linha `pods` com **APIVERSION** = `v1` e **NAMESPACED** = `true`.

**Por quê:** na prova, Pod quase sempre é `apiVersion: v1`, não `apps/v1`.

---

### Passo A3 — Campos de identificação (`metadata`)

```bash
kubectl explain pod.metadata --recursive | head -20
```

**Resultado esperado:** lista com `name`, `namespace`, `labels`, `annotations`, etc.

**Por quê:** `metadata` identifica o objeto; não define imagem nem CPU.

---

### Passo A4 — Campo obrigatório no `spec`

```bash
kubectl explain pod.spec.containers.image
```

**Resultado esperado:** descrição do campo `image` (string).

**Por quê:** sem `image` no container, o Pod não sobe.

**Checkpoint A:** você sabe que Pod = `v1` e que `image` fica em `spec.containers[]`.

### Fluxo declarativo (visão geral)

```text
  Manifesto YAML (spec)
           │
           │  kubectl apply
           ▼
      API Server ──────► etcd
           │
           ▼
      Controllers ─────► kubelet ──► atualiza status
```

---

## Bloco B — `spec` vs `status`

Abra `manifests/pod-minimal.yaml` no editor — é o Pod de referência:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-obj
  namespace: lab-objects-01
spec:
  containers:
    - name: nginx
      image: nginx:1.25-alpine
```

### Passo B1 — Aplicar o Pod de referência

```bash
kubectl apply -f manifests/pod-minimal.yaml
```

**Resultado esperado:** `pod/nginx-obj created` (ou `configured`).

**Por quê:** `apply` grava o **spec** no API Server; o scheduler/kubelet ainda precisam colocar o container a correr.

---

### Passo B2 — Esperar ficar Running

```bash
kubectl get pod nginx-obj -n lab-objects-01 -w
```

**Resultado esperado:** **STATUS** `Running`, **READY** `1/1`. Pare com `Ctrl+C`.

**Por quê:** `-w` mostra a transição de `status` (Pending → Running) em tempo real.

---

### Passo B3 — Ver spec e status no mesmo objeto

```bash
kubectl get pod nginx-obj -n lab-objects-01 -o yaml
```

> **Atenção:** o formato é `-o yaml` (três letras), não `yamlml`.

**Resultado esperado:** no YAML de saída, localize:

| Secção | Quem define | Exemplos |
|--------|-------------|----------|
| `spec` | Você (manifesto / apply) | `containers`, `image` |
| `status` | Cluster | `phase`, `podIP`, `conditions` |
| `metadata.uid`, `resourceVersion` | API Server | não estão no seu ficheiro inicial |

**Checkpoint B:** `status.phase: Running` e existe `status.podIP`.

---

## Bloco D — Reconciliação e Events

### Passo D1 — Linha do tempo do Pod

```bash
kubectl describe pod nginx-obj -n lab-objects-01
```

**Resultado esperado:** secção **Events** no final, por exemplo:

- `Scheduled` — scheduler escolheu o nó  
- `Pulling` / `Pulled` — imagem no nó  
- `Started` — container a correr  

**Por quê:** quando algo falha na prova, `describe` + Events costuma ser mais rápido que adivinhar.

---

### Passo D2 (opcional) — Delete + apply = recriar

```bash
kubectl delete pod nginx-obj -n lab-objects-01
kubectl apply -f manifests/pod-minimal.yaml
kubectl get pod nginx-obj -n lab-objects-01
```

**Por quê:** Pod “nu” não se reinicia sozinho; sem Deployment, você recria com `delete` + `apply`.

**Checkpoint D:** consegue explicar um Event do `describe`.

---

### ✅ Fim da Trilha 1

Se o checklist do topo da Trilha 1 está ok, **pode parar aqui** e voltar outro dia para a Trilha 2.

---

# Trilha 2 — Intermediária

**Objetivo:** corrigir manifestos e usar validação antes de aplicar.  
**Pré-requisito:** Trilha 1 concluída (`nginx-obj` Running).  
**Checklist ao terminar:** `nginx-incomplete` Running · `strict` rejeitou YAML inválido antes da correção.

---

## Bloco C — Completar manifesto incompleto

O ficheiro `manifests/pod-incomplete.yaml` vem **sem** `image` de propósito.

### Passo C1 — Editar o YAML (adicionar `image`)

O ficheiro traz um comentário `# Complete:` **entre** `name` e `ports` — a linha `image` deve ficar nesse nível (6 espaços), **não** dentro de `ports`.

**Por comando (recomendado no SSH):**

```bash
sed -i 's/# Complete: adicione image aqui (mesmo nível que name e ports)/      image: nginx:1.25-alpine/' manifests/pod-incomplete.yaml
grep -A5 'name: nginx' manifests/pod-incomplete.yaml
```

**Resultado esperado do `grep`:**

```text
    - name: nginx
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
```

**Se o `sed` anterior quebrou o YAML** (`mapping values are not allowed`):

```bash
cat > manifests/pod-incomplete.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: nginx-incomplete
  namespace: lab-objects-01
  labels:
    app: obj-lab
spec:
  containers:
    - name: nginx
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
EOF
```

**Alternativa — inserir após `name: nginx` e apagar o comentário:**

```bash
sed -i '/- name: nginx/a\      image: nginx:1.25-alpine' manifests/pod-incomplete.yaml
sed -i '/# Complete:/d' manifests/pod-incomplete.yaml
```

**Por editor:**

```bash
nano manifests/pod-incomplete.yaml
```

No container `nginx`, adicione (indentação alinhada com `name:`):

```yaml
      image: nginx:1.25-alpine
```

**Por quê:** campo obrigatório; sem `image` o apply falha ou o Pod não fica saudável.

---

### Passo C2 — Ver diff antes de aplicar

```bash
kubectl diff -f manifests/pod-incomplete.yaml
```

**Resultado esperado:** linhas `+` mostrando o que será criado/alterado (objeto novo = quase tudo com `+`).

**Por quê:** na prova, `diff` evita aplicar YAML errado no objeto errado.

---

### Passo C3 — Aplicar e confirmar

```bash
kubectl apply -f manifests/pod-incomplete.yaml
kubectl get pod nginx-incomplete -n lab-objects-01
```

**Resultado esperado:** `pod/nginx-incomplete created` e **STATUS** `Running`.

**Checkpoint C:** dois Pods no namespace: `nginx-obj` e `nginx-incomplete`.

---

## Bloco E — Validação no API Server

### Passo E1 — YAML com campo errado

O ficheiro `manifests/pod-invalid-field.yaml` usa `container:` em vez de `containers:`.

```bash
kubectl apply -f manifests/pod-invalid-field.yaml --validate=strict
```

**Resultado esperado:** **erro** (campo desconhecido / estrutura inválida). **Nenhum** Pod novo criado.

Verifique:

```bash
kubectl get pods -n lab-objects-01
```

**Por quê:** `--validate=strict` rejeita antes de gravar no etcd.

---

### Passo E2 — Corrigir e reaplicar

Erro no ficheiro: `container:` → deve ser `containers:` (lista).

**Por comando:**

```bash
sed -i 's/^  container:/  containers:/' manifests/pod-invalid-field.yaml
grep -A3 'containers:' manifests/pod-invalid-field.yaml
kubectl apply -f manifests/pod-invalid-field.yaml --validate=strict
```

**Por editor:** `nano manifests/pod-invalid-field.yaml` — troque `container:` por `containers:`.

**Resultado esperado:** `pod/nginx-invalid created` (ou `configured`).

---

### Passo E3 — `apiVersion` errado

```bash
kubectl apply -f manifests/pod-wrong-apiversion.yaml --validate=strict
```

**Resultado esperado:** falha — Pod não é `apps/v1`.

**Corrigir por comando:**

```bash
sed -i 's/apiVersion: apps\/v1/apiVersion: v1/' manifests/pod-wrong-apiversion.yaml
grep apiVersion manifests/pod-wrong-apiversion.yaml
kubectl apply -f manifests/pod-wrong-apiversion.yaml --validate=strict
```

**Por editor:** `nano manifests/pod-wrong-apiversion.yaml` — `apiVersion: v1`.

**Checkpoint E:** entende que strict protege o cluster de YAML “quase certo”.

---

### ✅ Fim da Trilha 2

Com Trilhas 1 e 2 ok, você já cobre o essencial do fundamento 1 para o dia a dia. A Trilha 3 aproxima do **ritmo de prova**.

---

# Trilha 3 — Nível prova

**Objetivo:** gerar YAML na pressa (`dry-run`) e metadados via CLI.  
**Pré-requisito:** Trilhas 1 e 2.

---

## Bloco F — Imperativo vs declarativo

### Passo F1 — Gerar manifesto sem criar Pod

```bash
kubectl run nginx-imp -n lab-objects-01 \
  --image=nginx:1.25-alpine \
  --dry-run=client -o yaml > /tmp/nginx-imp.yaml
cat /tmp/nginx-imp.yaml
```

**Resultado esperado:** YAML completo no terminal/arquivo, com campos default (`restartPolicy: Always`, etc.).

**Por quê:** fluxo comum na prova: `kubectl run ... --dry-run=client -o yaml > arquivo.yaml` → editar → `apply -f`.

---

### Passo F2 — Comparar com o seu manifesto

Compare `/tmp/nginx-imp.yaml` com `manifests/pod-minimal.yaml` (labels, `ports`, campos extras).

---

### Passo F3 — Annotation pela CLI

```bash
kubectl annotate pod nginx-obj -n lab-objects-01 study.cka/exercise=guided
```

**Por quê:** annotations são metadados; não substituem labels para seleção de Service/Deployment.

---

### Passo F4 — Ler annotation com jsonpath

```bash
kubectl get pod nginx-obj -n lab-objects-01 \
  -o jsonpath='{.metadata.annotations.study\.cka/exercise}{"\n"}'
```

**Resultado esperado:** linha com `guided`

**Checkpoint F:** relaciona comando imperativo (`run` + dry-run) com workflow declarativo (`apply` + YAML).

---

### ✅ Fim da Trilha 3 — Lab 01 completo

---

## Critério de sucesso (por trilha)

### Trilha 1

- [ ] Namespace `lab-objects-01` existe  
- [ ] `nginx-obj` em **Running**  
- [ ] Explica: **spec** = desejado; **status** = observado  
- [ ] `kubectl describe pod nginx-obj` mostra Events compreensíveis  

### Trilha 2

- [ ] `nginx-incomplete` em **Running**  
- [ ] `pod-invalid-field.yaml` **falha** com `--validate=strict` antes da correção  

### Trilha 3

- [ ] Gerou YAML com `--dry-run=client -o yaml`  
- [ ] Annotation lida via `jsonpath` (`guided`)  

---

## Troubleshooting

| Sintoma | O que verificar | Comando |
|---------|-----------------|---------|
| `namespace not found` | Passo A1 não feito | `kubectl apply -f namespace.yaml` |
| `Forbidden` | kubectl no cluster/contexto errado | `kubectl config current-context` |
| `ImagePullBackOff` | imagem/tag inválida | `kubectl describe pod <nome> -n lab-objects-01` |
| Pod `Pending` muito tempo | nó sem recursos ou CNI | `kubectl get nodes` · `kubectl describe pod ...` |
| Comando não acha ficheiro | pasta errada | `pwd` · `ls manifests/` |
| `mapping values are not allowed` | indentação YAML errada (ex.: `image` dentro de `ports`) | `grep -A6 'name: nginx' manifests/pod-incomplete.yaml` · refaça o C1 |

---

## Limpeza

```bash
kubectl delete namespace lab-objects-01
```

---

## Próximo passo

- **Lab 02 (neste repo):** [../02-namespaces/README-guided.md](../02-namespaces/README-guided.md) — publique com `CKA_LABS=02-namespaces ./kubernetes/scripts/deploy-cka-labs.sh`
- **Teoria (projeto CKA separado):** fundamento 2 — Namespaces
