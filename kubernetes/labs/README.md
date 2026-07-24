# Labs CKA (cópia no repositório)

Manifestos e guias do **projeto CKA** (estudo teórico) estão **copiados** para cá. Este repositório (`cloud-reliability-lab`) é independente: sobe o cluster na AWS e publica estes labs no control-plane.

| Pasta | Tópico | Bootstrap automático |
|-------|--------|----------------------|
| [`01-objects/`](01-objects/) | Objetos Kubernetes | `namespace.yaml` → `lab-objects-01` |
| [`02-namespaces/`](02-namespaces/) | Namespaces e isolamento | `manifests/namespaces.yaml` |

Os Pods de exercício **não** são aplicados no bootstrap — siga o `README-guided.md` de cada lab.

## Fluxo automático

Na raiz do `cloud-reliability-lab`, após `terraform apply`:

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
./kubernetes/scripts/wait-for-cluster.sh
```

Por padrão publica só o lab **01-objects**. Para incluir o 02:

```bash
CKA_LABS=01-objects,02-namespaces ./kubernetes/scripts/wait-for-cluster.sh
```

## Publicar manualmente

```bash
./kubernetes/scripts/deploy-cka-labs.sh
CKA_LABS=02-namespaces ./kubernetes/scripts/deploy-cka-labs.sh
```

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `CKA_LABS` | `01-objects` | Pastas em `kubernetes/labs/` |
| `CKA_LABS_DIR` | `kubernetes/labs` | Origem local (dentro deste repo) |
| `CKA_DEPLOY_LABS` | `true` | Em `wait-for-cluster.sh` (`false` desliga) |
| `CKA_SKIP_COPY` | — | `true` = só `kubectl apply` do bootstrap |

## No control-plane (SSH)

```text
/home/ubuntu/cka-labs/
  01-objects/     # namespace + manifests + README-guided.md
  02-namespaces/
```

## Atualizar a partir do projeto CKA

Quando alterar labs no repositório de estudo CKA, sincronize a cópia:

```bash
./kubernetes/scripts/sync-cka-labs.sh
```

Requer o kit CKA no caminho padrão `../CKA` (ajuste com `CKA_SOURCE_ROOT`).
