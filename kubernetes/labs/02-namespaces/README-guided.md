# Lab 02 — Namespaces e isolamento (modo guiado)

**Tempo:** 45–60 min · **Refs:** [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) · [DNS for Services](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) · [api-resources](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#api-resources)

**Teoria:** [Namespaces e isolamento](../2.%20Objetos%2C%20Estado%20e%20Isolamento%20com%20Namespaces%20no%20Kubernetes.md)

## Objetivo

Criar múltiplos Namespaces, implantar recursos com **o mesmo nome** em escopos diferentes, testar **DNS interno** (curto e FQDN), distinguir recursos **namespaced** vs **cluster-scoped** e usar `-n` vs contexto do `kubectl`.

## Por quê?

Item 2 do checklist em `4. fundamentals.md`. Na CKA, confundir namespace padrão, esquecer `-n` ou errar FQDN cross-namespace é causa frequente de “Service não resolve”.

## Como usar este guia

Cada passo traz o comando, a explicação das partes e o que observar na saída — no mesmo padrão do [Lab 01](../../1.%20Objetos%20Kubernetes/lab/README-guided.md).

> **Diagramas:** no preview do editor, use os blocos ASCII (`text`). Para fluxogramas gráficos, abra [diagrams.html](diagrams.html) no navegador.

---

## Bloco A — Criar Namespaces e escopo de recursos

### Passo A1 — Aplicar os Namespaces do lab

```bash
kubectl apply -f manifests/namespaces.yaml
```

| Parte | Significado |
|-------|-------------|
| **`apply`** | Declarativo: garante que `lab-ns-vendas` e `lab-ns-infra` existam com os labels do YAML. |
| **`namespaces.yaml`** | Dois objetos `kind: Namespace` no mesmo arquivo, separados por `---`. |

**O que observar:** `namespace/lab-ns-vendas created` e `namespace/lab-ns-infra created`.

**Conceito:** o objeto **Namespace** é **cluster-scoped** (ele mesmo não “mora” dentro de outro namespace), mas define um limite lógico para os demais recursos.

---

### Passo A2 — Listar Namespaces

```bash
kubectl get ns
```

| Parte | Significado |
|-------|-------------|
| **`get ns`** | Atalho de `namespaces`; lista todos os namespaces do cluster. |

**O que observar:** além dos do lab, aparecem `default`, `kube-system`, `kube-public`, `kube-node-lease` (namespaces do sistema). Não use `kube-` como prefixo em namespaces seus em produção.

---

### Passo A3 — Filtrar recursos namespaced

```bash
kubectl api-resources --namespaced=true | head -15
```

| Parte | Significado |
|-------|-------------|
| **`api-resources`** | Catálogo de tipos que a API expõe. |
| **`--namespaced=true`** | Só recursos que **exigem** namespace (`pods`, `services`, etc.). |

**O que observar:** coluna **NAMESPACED** = `true` e nomes como `pods`, `services`, `configmaps`.

---

### Passo A4 — Filtrar recursos de cluster

```bash
kubectl api-resources --namespaced=false | head -15
```

**O que observar:** `nodes`, `persistentvolumes`, `storageclasses`, `namespaces` — **não** aceitam `-n` porque são globais ao cluster.

**Checkpoint:** você explica por que `kubectl get nodes -n lab-ns-vendas` não faz sentido (nodes não são namespaced).

### Visão geral — escopo de namespace

```text
  Cluster
  ┌──────────────────────┐    ┌──────────────────────┐
  │   lab-ns-vendas      │    │   lab-ns-infra       │
  │   Pod db ── Service db│    │   Pod db ── Service db│
  └──────────────────────┘    └──────────────────────┘
         mesmo nome "db" — namespaces diferentes (sem conflito)

  Node, PV, StorageClass …  →  escopo de cluster (sem namespace)
```

Mesmo nome (`db`), **dois escopos** — sem conflito. Objetos como **Node** ficam fora de qualquer caixa de namespace.

> Diagrama interativo (navegador): abra [diagrams.html](diagrams.html) na pasta deste lab.

---

## Bloco B — Mesmo nome, namespaces diferentes

### Passo B1 — Stack em `lab-ns-vendas`

```bash
kubectl apply -f manifests/stack-vendas.yaml
```

**O que faz:** cria Pod `db` e Service `db` **somente** em `lab-ns-vendas` (o `namespace:` está no metadata de cada objeto).

---

### Passo B2 — Stack em `lab-ns-infra`

```bash
kubectl apply -f manifests/stack-infra.yaml
```

**O que faz:** repete os **mesmos nomes** (`db`) em outro namespace — válido porque unicidade de nome é **por namespace**, não global.

---

### Passo B3 — Comparar listagens

```bash
kubectl get pods,svc -n lab-ns-vendas
kubectl get pods,svc -n lab-ns-infra
```

| Parte | Significado |
|-------|-------------|
| **`pods,svc`** | Vários tipos na mesma consulta, separados por vírgula. |
| **`-n`** | Restringe a leitura a **um** namespace por vez. |

**O que observar:** em cada namespace, Pod `db` e Service `db` com IPs/ClusterIP **diferentes**.

**Checkpoint:** dois times podem usar o padrão de nome `db` sem colidir, desde que o namespace seja diferente.

---

## Bloco C — DNS: resolução curta e FQDN

### Visão geral — resolução DNS no cluster

```text
  lab-ns-vendas                         lab-ns-infra
  ┌─────────────────────┐               ┌──────────────┐
  │ Pod dns-test        │               │ Service db   │
  │      │              │               └──────▲───────┘
  │      ├─ nslookup db ──► Service db      │
  │      │   (mesmo NS)   │                 │
  │      └─ nslookup db.lab-ns-infra.svc.cluster.local
  └─────────────────────┘               (outro NS)
```

**Curto** = mesmo namespace. **FQDN** = cruzar para outro namespace explicitamente.

### Passo C1 — Subir o Pod de teste DNS

```bash
kubectl apply -f manifests/dns-test.yaml
kubectl wait --for=condition=Ready pod/dns-test -n lab-ns-vendas --timeout=90s
```

| Parte | Significado |
|-------|-------------|
| **`wait`** | Bloqueia até a condição ser verdadeira (ou timeout). |
| **`--for=condition=Ready`** | Espera o Pod passar nos readiness checks (busybox fica Ready rápido). |
| **`--timeout=90s`** | Evita espera infinita se o cluster estiver lento. |

---

### Passo C2 — Resolução curta (mesmo namespace)

```bash
kubectl exec -n lab-ns-vendas dns-test -- nslookup db
```

| Parte | Significado |
|-------|-------------|
| **`exec`** | Executa comando **dentro** de um container do Pod. |
| **`dns-test`** | Pod cliente em `lab-ns-vendas`. |
| **`nslookup db`** | Pergunta ao DNS do cluster pelo nome **curto** `db`. |

**O que observar:** o endereço resolvido refere-se ao Service `db` em **lab-ns-vendas** (resolução curta = mesmo namespace do Pod).

**Formato implícito:** `db.lab-ns-vendas.svc.cluster.local`

---

### Passo C3 — Resolução cross-namespace (FQDN)

```bash
kubectl exec -n lab-ns-vendas dns-test -- nslookup db.lab-ns-infra.svc.cluster.local
```

**O que faz:** consulta explícita ao Service `db` no namespace **infra**.

| Segmento FQDN | Significado |
|-----------------|-------------|
| **`db`** | Nome do Service |
| **`lab-ns-infra`** | Namespace alvo |
| **`svc.cluster.local`** | Sufixo DNS padrão do cluster |

**O que observar:** IP do ClusterIP do Service em **infra**, diferente do passo C2.

**Checkpoint:** de `vendas` para acessar `db` em `infra`, o FQDN completo (ou política DNS equivalente) é obrigatório.

---

### Passo C4 (opcional) — Ver registros no Service

```bash
kubectl describe svc db -n lab-ns-infra
```

**O que observar:** **Endpoints** apontando para o Pod `db` no mesmo namespace — DNS e Service só funcionam de ponta a ponta se o backend existir.

---

## Bloco D — `-n` pontual vs namespace no contexto

### Passo D1 — Ver namespace atual do contexto

```bash
kubectl config view --minify -o jsonpath='{..namespace}{"\n"}'
```

**O que faz:** lê o namespace **default** gravado no contexto atual do `kubeconfig` (pode estar vazio = usa `default`).

---

### Passo D2 — Fixar namespace no contexto

```bash
kubectl config set-context --current --namespace=lab-ns-vendas
kubectl get pods
```

| Parte | Significado |
|-------|-------------|
| **`set-context --current`** | Altera o contexto em uso (não muda cluster, só defaults). |
| **`--namespace=...`** | Próximos `kubectl get` sem `-n` usam `lab-ns-vendas`. |

**O que observar:** lista só Pods de vendas (inclui `db` e `dns-test`).

---

### Passo D3 — Voltar ao comportamento neutro

```bash
kubectl config set-context --current --namespace=default
```

**Conceito:** na prova, muitos preferem **sempre** usar `-n` explícito para não aplicar recurso no namespace errado por engano.

**Checkpoint:** você diferencia “namespace no contexto” de “namespace no manifesto YAML”.

---

## Bloco E — Namespaces do sistema e governança

### Passo E1 — Inspecionar `kube-system`

```bash
kubectl get pods -n kube-system
```

**O que observar:** componentes do plano de controle (CoreDNS, kube-proxy, etc.). Falhas aqui afetam **todo** o cluster.

---

### Passo E2 — Label injetada pelo Kubernetes

```bash
kubectl get namespace lab-ns-vendas -o yaml | grep -A2 labels
```

**O que observar:** label `kubernetes.io/metadata.name: lab-ns-vendas` — imutável e útil em NetworkPolicies (tópico futuro).

---

### Passo E3 — Listar com labels do lab

```bash
kubectl get ns -l study.cka/module=namespaces
```

| Parte | Significado |
|-------|-------------|
| **`-l`** | *Label selector*: filtra namespaces (ou outros recursos) por label. |

**Checkpoint:** você localiza rapidamente os namespaces criados por este lab.

---

## Bloco F — Validação de nome (RFC 1123)

### Passo F1 — Namespace com nome inválido

```bash
kubectl apply -f manifests/namespace-invalid.yaml
```

**O que observar:** erro do API Server — `lab_ns_invalid` contém **underscore**, inválido para nome de namespace (RFC 1123: minúsculas, números, hífen).

---

### Passo F2 — Criar via CLI (comparação)

```bash
kubectl create namespace lab-ns-demo
kubectl delete namespace lab-ns-demo
```

| Comando | Quando usar na prova |
|---------|----------------------|
| **`create namespace`** | Criação rápida imperativa (nome único, sem reaplicar YAML). |
| **`delete namespace`** | Remove namespace e **todos** os recursos dentro (cascata). |

> **Aviso TLD overlap (teoria):** nunca crie namespace `com` com Service `google` — `google.com` seria resolvido **dentro** do cluster. Os nomes deste lab (`lab-ns-vendas`) evitam esse anti-padrão.

**Checkpoint:** você valida nomes de namespace antes de aplicar YAML em produção.

---

## Critério de sucesso

- Namespaces `lab-ns-vendas` e `lab-ns-infra` existem
- Pod e Service `db` em **ambos** os namespaces, sem conflito
- `nslookup db` de dentro de `dns-test` resolve o Service local
- `nslookup db.lab-ns-infra.svc.cluster.local` resolve o Service em infra
- Você lista um recurso namespaced e um cluster-scoped corretamente
- `namespace-invalid.yaml` é rejeitado pelo API Server

## Troubleshooting

| Sintoma | Causa provável | Comando útil |
|---------|----------------|--------------|
| `nslookup: can't resolve` | CoreDNS indisponível | `kubectl get pods -n kube-system -l k8s-app=kube-dns` |
| `nslookup` OK mas curl falha | sem backend no Service | `kubectl get endpoints db -n <ns>` |
| Pod em namespace errado | YAML sem `namespace:` | `kubectl get pod <nome> -o jsonpath='{.metadata.namespace}{"\n"}'` |
| `NotFound` no apply | namespace não criado | `kubectl apply -f manifests/namespaces.yaml` |
| `wait` timeout | cluster sem recursos | `kubectl describe pod dns-test -n lab-ns-vendas` |

## O que cai no blueprint CKA?

- `kubectl get/create/delete namespace`
- `-n` / `--namespace` e `kubectl config set-context`
- FQDN `<svc>.<ns>.svc.cluster.local`
- `api-resources --namespaced=true|false`
- Não confundir escopo de Namespace com escopo de Node/PV

## Próximo passo

- **Teoria:** [Fundamento 3 — Pods](../../3.%20Pods%20e%20Workloads/3.%20Pods%20e%20Arquitetura%20de%20Workloads%20no%20Kubernetes.md)
- **Lab:** [Lab 01 — Objetos](../../1.%20Objetos%20Kubernetes/lab/README.md) (pré-requisito) · [Lab domínio RBAC](../../../labs/01-cluster-rbac) (quando for estudar permissões)

## Limpeza

```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace lab-ns-vendas lab-ns-infra
```

**O que faz:** restaura contexto e apaga os namespaces do lab (e todo conteúdo dentro deles).
