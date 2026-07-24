# cloud-reliability-lab

Lab na AWS: VPC, 2× Ubuntu (control-plane + worker), kubeadm + Calico. Acesso por **SSH**; opcionalmente **`kubectl` no PC** ([Apêndice A](#apendice-a-kubectl-no-seu-computador)). No fim: **`terraform destroy`**.

## TL;DR

Para quem já tem AWS CLI + Terraform configurados.

```bash
git clone https://github.com/m4rlonalvesilva/cloud-reliability-lab.git cloud-reliability-lab
cd cloud-reliability-lab
aws sts get-caller-identity
# se sua conta exigir MFA para API:
source ./scripts/aws-mfa-session.sh
cd terraform && cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars: aws_region, allow_ssh_cidrs, ec2_key_name, instance_type=t3.small+
terraform init && terraform validate && terraform plan
terraform apply -auto-approve
cd ..
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
./kubernetes/scripts/wait-for-cluster.sh   # publica labs em kubernetes/labs/ quando Ready
# na raiz do repositório (o cd .. acima já voltou da pasta terraform)
cd terraform && terraform destroy
```

## Índice

- [Arquitetura na AWS](#arquitetura-na-aws)
- [Estrutura do repositório](#estrutura-do-repositório)
- [1. Ferramentas](#1-ferramentas)
- [2. Conta AWS + billing](#2-conta-aws--billing)
- [3. Clonar o repositório](#3-clonar-o-repositório)
- [4. Credenciais AWS no terminal](#4-credenciais-aws-no-terminal)
- [5. MFA obrigatório (política ForceMFA)](#5-mfa-obrigatório-política-forcemfa)
- [6. Par de chaves EC2 (Key Pair)](#6-par-de-chaves-ec2-key-pair)
- [7. Criar e editar terraform.tfvars](#7-criar-e-editar-terraformtfvars)
- [8. Subir a infraestrutura (terraform apply)](#8-subir-a-infraestrutura-terraform-apply)
- [9. Aguardar o Kubernetes (bootstrap)](#9-aguardar-o-kubernetes-bootstrap)
- [10. Labs CKA no cluster](#10-labs-cka-no-cluster)
- [11. Usar o cluster](#11-usar-o-cluster)
- [12. Encerrar e não deixar custo rodando](#12-encerrar-e-não-deixar-custo-rodando)
- [Se algo der errado](#se-algo-der-errado)
- [Opcional: Git e editor](#opcional-git-e-editor)
- [Apêndice A: kubectl no seu computador](#apendice-a-kubectl-no-seu-computador)

## Arquitetura na AWS

```text
Internet
  -> Internet Gateway
  -> VPC
  -> Subnet pública
  -> 2x EC2 Ubuntu (SSH restrito por CIDR)
     - nó 0: control-plane
     - nó 1+: workers
```

**Rede:** SSH **22** e (opcional) API **6443** só para `allow_ssh_cidrs`; tráfego entre EC2 do mesmo SG permitido.

## Estrutura do repositório

```text
cloud-reliability-lab/
  ├─ .gitattributes              # regras Git (EOL)
  ├─ .gitignore                  # o que não versionar
  ├─ .kube-generated/            # local: kubeconfig (import-kubeconfig-local.sh)
  ├─ cluster-lab.generated.txt   # local: resumo SSH (terraform apply)
  ├─ kubernetes/
  │  ├─ labs/                    # labs CKA (cópia): manifestos + guias; publicados no cluster
  │  └─ scripts/                 # bootstrap EC2 + wait / deploy-cka-labs / import-kubeconfig
  ├─ README.md                   # este guia
  ├─ scripts/                    # MFA, IP público (na tua máquina)
  └─ terraform/                  # .tf, apply; dentro: .terraform/ e *.tfstate (local)
```

---

## 1. Ferramentas

**Instalar** (PowerShell ou CMD) — `winget` instala Git, AWS CLI, Terraform, jq, kubectl e OpenSSH:

```powershell
winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements
winget install -e --id Amazon.AWSCLI --accept-package-agreements --accept-source-agreements
winget install -e --id Hashicorp.Terraform --accept-package-agreements --accept-source-agreements
winget install -e --id jqlang.jq --accept-package-agreements --accept-source-agreements
winget install -e --id Kubernetes.kubectl --accept-package-agreements --accept-source-agreements
winget install -e --id Microsoft.OpenSSH.Beta --accept-package-agreements --accept-source-agreements
```

Depois do `winget`, **feche e abra o terminal** (ou abra um Git Bash novo); só assim o `PATH` atualiza para **validar** abaixo.

**Validar** (Git Bash):

```bash
git --version && aws --version && terraform version && ssh -V && jq --version && kubectl version --client
```

---

## 2. Conta AWS + billing

Entre no [console AWS](https://console.aws.amazon.com) com a região **`us-east-1`** (Norte da Virgínia) selecionada.

### MFA no root

1. Clique no **nome da conta** (canto superior direito) → **Security credentials** (credenciais de segurança).
2. Em **Multi-factor authentication (MFA)** → **Assign MFA device** (atribuir dispositivo MFA).
3. Escolha **Authenticator app** (recomendado), escaneie o QR e confirme com **dois códigos** consecutivos.

### Root sem Access Keys

Objetivo: **root com zero Access Keys**.

1. Nome da conta (canto superior direito) → **Security credentials**.
2. Abra **Access keys**.
3. Se existir chave ativa no root: **Delete** (ou **Deactivate** e depois **Delete**).

### Billing e alertas

No console AWS, abra o serviço **Billing** (faturamento / custos).

- **Cost Explorer:** habilite se ainda não estiver ativo.
- **Budgets** → **Create budget** → **Cost budget**:
  - defina um valor mensal (ex.: 5 USD ou 20 USD);
  - configure alertas por e-mail (ex.: 80% e 100%).

### Criar usuário IAM do laboratório

O Terraform precisa de permissões para **EC2**, **VPC**, **IAM** (instance profile) e **SSM Parameter Store**. Em **conta pessoal de estudo**, o caminho mais simples é o grupo **Administrators**; em produção, use política com o mínimo necessário.

1. **IAM** → **Usuários** → **Criar usuário**.
2. **Nome:** `cloud-reliability-lab`.
3. **Não** marque acesso ao **console**.
4. Em **Opções de permissões**, escolha **Adicionar usuário ao grupo**.
5. Selecione o grupo **Administrators** (conta pessoal de estudo).
6. **Criar usuário**.
7. No usuário criado: **Credenciais de segurança** → **Chaves de acesso** → **Criar chave**.
8. **Tipo de uso:** **CLI**.
9. Na tela final, copie **Access Key ID** e **Secret Access Key** e baixe o arquivo **.csv**.
10. Guarde o `.csv` em local **seguro** e **fora** do repositório.
11. Depois de guardar com segurança, **apague** o `.csv` da pasta **Downloads** (ou outro local temporário).

**Nunca** coloque Access Key ID, Secret Access Key, `.csv` ou credenciais em GitHub, README, código ou `terraform.tfvars`.

**Checklist:** `us-east-1`, MFA no root, root sem Access Keys, budget, usuário IAM com chave CLI guardada, EC2 acessível na região.

---

## 3. Clonar o repositório

```bash
git clone https://github.com/m4rlonalvesilva/cloud-reliability-lab.git cloud-reliability-lab
cd cloud-reliability-lab
```

## 4. Credenciais AWS no terminal

```bash
aws configure   # user IAM + região ex.: us-east-1
aws sts get-caller-identity
```

Mesmo terminal para os passos Terraform.

---

## 5. MFA obrigatório (*ForceMFA*)

Só se `terraform plan` der **403** / *explicit deny* (API sem MFA). Na raiz do repo:

```bash
source ./scripts/aws-mfa-session.sh
echo "$AWS_SESSION_TOKEN"   # deve imprimir algo
aws sts get-caller-identity
```

Repetir `terraform plan` no **mesmo** shell.

---

## 6. Par de chaves EC2 (Key Pair)

EC2 → **Key Pairs** → **Create key pair** → nome = valor de `ec2_key_name` no Terraform. Guarde o **`.pem`** fora do repo. Git Bash: `/c/Users/.../chave.pem`.

---

## 7. Criar e editar `terraform.tfvars`

`ec2_key_name` = nome exato do Key Pair (passo 6). A mesma `.pem` serve para `SSH_KEY_PATH`.

```bash
cd terraform && cp terraform.tfvars.example terraform.tfvars
cd .. && ./scripts/get-my-public-ip.sh   # para allow_ssh_cidrs
```

Edite **`terraform/terraform.tfvars`**:

| Variável | Obrigatório | Dica |
|----------|-------------|------|
| `aws_region` | sim | Ex.: `us-east-1` |
| `allow_ssh_cidrs` | sim | Seu IP com `/32` |
| `ec2_key_name` | sim | Nome **exato** do Key Pair |
| `instance_type` | muito recomendado | **`t3.small` ou maior** — com ~2 GiB RAM por nó o kubeadm sobe; `t3.micro` costuma falhar |
| `ec2_instance_count` | opcional | Padrão `2` (um control-plane e um worker) |
| `expose_kubernetes_api_https` | depende | `false` só SSH; `true` + [Apêndice A](#apendice-a-kubectl-no-seu-computador) |
| `project_name` | opcional | Afeta tags e nome sugerido do contexto no kubeconfig local |

**`expose_kubernetes_api_https`:** `false` ou omitir = só SSH + `kubectl` **na** VM (sem 6443). `true` + novo `apply` = `kubectl` **no PC** ([Apêndice A](#apendice-a-kubectl-no-seu-computador)), mesmos CIDRs que o SSH na **6443**.

Custo: EC2 ligadas = cobrança. Fim: **`terraform destroy`**. Não versionar `terraform.tfvars`, `.pem`, estado Terraform.

---

## 8. Subir a infraestrutura (`terraform apply`)

Na raiz:

```bash
source ./scripts/aws-mfa-session.sh   # se precisar de MFA (passo 5)
terraform -chdir=terraform plan
terraform -chdir=terraform apply -auto-approve   # ou apply interativo + yes
```

Primeira vez em `terraform/`: `terraform init` (opcional `fmt` / `validate`). 403 no plan → passo 5, mesmo shell.

Sucesso: outputs no terminal; **`cluster-lab.generated.txt`** na raiz (resumo SSH; estado real = Terraform).

---

## 9. Aguardar o Kubernetes (bootstrap)

Primeiro boot: containerd, kubeadm, join (SSM), Calico — tipicamente **~3 min** após o `apply`. Log no CP (com SSH): `sudo tail -f /var/log/k8s-bootstrap.log`

Na **raiz**, com `.pem`:

```bash
export SSH_KEY_PATH="/c/Users/SEU_USUARIO/caminho/sua-chave.pem"
./kubernetes/scripts/wait-for-cluster.sh
```

Objetivo: todos os nós **Ready** (por padrão 2, salvo `ec2_instance_count`).

Ao terminar com sucesso, o script publica automaticamente o **Lab 01** em [`kubernetes/labs/01-objects/`](kubernetes/labs/01-objects/) (namespace `lab-objects-01` + ficheiros em `~/cka-labs/01-objects` no control-plane). Detalhes: [`kubernetes/labs/README.md`](kubernetes/labs/README.md).

Para **não** publicar os labs neste passo: `CKA_DEPLOY_LABS=false ./kubernetes/scripts/wait-for-cluster.sh`

---

## 10. Labs CKA no cluster

Os manifestos estão **dentro deste repositório** em `kubernetes/labs/` (cópia do projeto de estudo CKA, repositório separado). O [`deploy-cka-labs.sh`](kubernetes/scripts/deploy-cka-labs.sh) copia para o control-plane e aplica só o bootstrap; os exercícios seguem o `README-guided.md` de cada lab.

| Ação | Comando |
|------|---------|
| Automático (após Ready) | `./kubernetes/scripts/wait-for-cluster.sh` |
| Manual | `./kubernetes/scripts/deploy-cka-labs.sh` |
| Lab 01 + 02 | `CKA_LABS=01-objects,02-namespaces ./kubernetes/scripts/deploy-cka-labs.sh` |
| Atualizar cópia a partir do repo CKA | `./kubernetes/scripts/sync-cka-labs.sh` |

Estudo no cluster: SSH → `cd ~/cka-labs/01-objects` e abra `README-guided.md`.

---

## 11. Usar o cluster

IP do control-plane: `cluster-lab.generated.txt` ou output Terraform (`Role: control-plane`).

```bash
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new ubuntu@IP_PUBLICO
kubectl get nodes -o wide
kubectl get pods -A
```

Se `kubectl` falhar: bootstrap ainda em curso → log no passo 9.

---

## 12. Encerrar e não deixar custo rodando

`cd terraform && terraform destroy` — confirmar `yes`.

---

## Se algo der errado

| Problema | Ação |
|----------|------|
| **403** no `terraform plan` | [Passo 5](#5-mfa-obrigatório-política-forcemfa), mesmo shell |
| **SSH** falha | IP mudou → `allow_ssh_cidrs` + [Passo 8](#8-subir-a-infraestrutura-terraform-apply) |
| Nós não **Ready** | `t3.small`+, tempo, log no CP ([Passo 9](#9-aguardar-o-kubernetes-bootstrap)) |
| `kubectl` no PC | `expose_kubernetes_api_https` + apply; [Apêndice A](#apendice-a-kubectl-no-seu-computador) |
| `wait-for-cluster` | `SSH_KEY_PATH`, `jq`, cluster a subir ([Passo 9](#9-aguardar-o-kubernetes-bootstrap)) |

Log CP: `sudo tail -100 /var/log/k8s-bootstrap.log`

---

## Opcional: Git e editor

`git config --global user.name` / `user.email` se for commitar; extensão Terraform na IDE se quiser.

---

## Apêndice A: kubectl no seu computador

Você já rodou **`terraform apply`**. Em **`terraform/terraform.tfvars`**: `expose_kubernetes_api_https = true` e outro **`apply`** (API **6443**, mesmo CIDR que o SSH). **`kubectl`**: [§1](#1-ferramentas).

1. Abra o **Git Bash** e `cd` até a **raiz** do repositório `cloud-reliability-lab`.
2. Rode **um** comando; entre aspas, use **o caminho completo** do ficheiro **`.pem`** no seu computador:

```bash
./kubernetes/scripts/setup-kubectl-local.sh "/c/Users/SEU_USUARIO/Documents/cloud-reliability-lab-key.pem"
```

3. No fim aparece **`SUCESSO`** ou **`FALHA`** (o teste corre **dentro** do script). **FALHA** → veja o erro no ecrã.
4. **Sempre** rode a linha **`source ...`** que o script imprime (na **mesma** janela ou noutra). Ao correr `./setup-....sh`, o shell cria um **processo filho**: o `export KUBECONFIG` lá dentro **não fica** no Git Bash quando o script acaba. O `source` aplica o `KUBECONFIG` no **seu** shell; depois o `kubectl` funciona nessa janela.

**Se deu FALHA:** `.pem` errada; falta `expose_kubernetes_api_https` + `apply`; IP fora de `allow_ssh_cidrs`; nós ainda não Ready; `kubectl` fora do `PATH`.
