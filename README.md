# cloud-reliability-lab

Laboratório prático de **estudo CKA**, **infraestrutura como código** e **troubleshooting** na AWS. A base do lab são **2 máquinas Linux** para treino de cluster, comandos e diagnóstico, com tudo organizado em fases no mesmo repositório.

**Para quem está começando:** não é preciso saber AWS ou Terraform para **ler** este guia. Siga o [tutorial passo a passo](#tutorial-passo-a-passo) **na ordem** — na prática, cada *entrega* do tutorial será **um passo por vez** (instalação, conta, credencial ou comando), para você estudar sem sobrecarga.

---

## O que é este projeto

Você sobe e gerencia uma infraestrutura simples na AWS (rede + **2 máquinas Linux**) usando **Terraform**, criando um ambiente real para estudar CKA com práticas de segurança e documentação no estilo **SRE**.

---

## Estrutura das pastas (visão geral)

```text
cloud-reliability-lab/
├── scripts/         # Utilitários (ex.: IP público); detalhes em scripts/README.md
├── terraform/
├── .gitignore
└── README.md        # Você está aqui — tutorial passo a passo no topo
```

---

## Arquitetura inicial

Quando você chegar na parte de Terraform, o código cria algo nesta linha:

```text
Internet → Internet Gateway → VPC → subnet pública → 2× EC2 Ubuntu (SSH só dos IPs que você informar)
```

Detalhes técnicos dos recursos estão nos comentários em `terraform/*.tf`.

---

## Tutorial passo a passo

**Objetivo deste tutorial:** ao longo dos passos, deixar **tudo pronto** para a Fase 1 — ferramentas instaladas na sua máquina, **conta AWS** utilizável, **credenciais** configuradas de forma segura (sem segredo no Git), repositório no **GitHub**, ambiente **Terraform** para criar e destruir a infra na AWS com confiança, e no **Passo 14** enviar alterações ao GitHub com `commit` / `push`.

> **Como usar este bloco:** siga a **ordem** da tabela. Só avance para o próximo número depois de concluir o anterior. Cada linha virará uma seção **### Passo N — …** neste README, com um único foco por vez. Versões “verificadas no lab” são exemplos; ao instalar pelo site oficial, a sua versão pode ser **mais nova**.

### Índice — do zero ao ciclo completo do lab

| Passo | O que você vai fazer | Status no README |
|------:|----------------------|------------------|
| 1 | Instalar o **Git** (Windows) | Documentado abaixo |
| 2 | Configurar identidade Git (`user.name` / `user.email`) | Documentado abaixo |
| 3 | **Conta AWS:** criar ou entrar na conta, **us-east-1**, higiene de **Access Keys**, **billing** (sem segredos no Git) | Documentado abaixo |
| 4 | **IAM:** usuário do lab + **Access Key** para CLI/Terraform (ou **SSO** no trabalho) — o que **nunca** versionar | Documentado abaixo |
| 5 | Instalar **AWS CLI v2** e validar; depois `aws configure` (ou `aws configure sso`) e testar identidade | Documentado abaixo |
| 6 | Instalar **Terraform** e validar (`terraform version`) | Documentado abaixo |
| 7 | **GitHub:** chave SSH, repositório remoto, `git remote` e primeiro `push` (ou `clone`) | Documentado abaixo |
| 8 | Na AWS: criar **EC2 Key Pair** (`.pem`) na mesma região do lab; guardar fora do repositório | Documentado abaixo |
| 9 | Ligar **MFA** no usuário IAM e **carregar sessão** no terminal antes do Terraform | Documentado abaixo |
| 10 | No projeto: `terraform.tfvars` a partir do example + seu **IP** para o security group (`scripts/get-my-public-ip.sh`) | Documentado abaixo |
| 11 | **Terraform:** `init` → `fmt` → `validate` → `plan` → `apply` (outputs no fim do apply) | Documentado abaixo |
| 12 | **Validar:** console AWS, **SSH** nas duas Ubuntu (IPs do Passo 11) | Documentado abaixo |
| 13 | **Encerrar o lab:** `terraform destroy` e boas práticas de custo | Documentado abaixo |
| 14 | **Commit** e **push** no GitHub (`.gitignore` protege segredos) | Documentado abaixo |
| *(opc.)* | Extensão **Terraform/HCL** na **IDE** de sua preferência | Documentado abaixo |

---

### Passo 1 — Instalar Git (Windows)

**Ação**

1. Instale o Git para Windows pelo instalador oficial (site **git-scm.com**, secção de download para Windows).
2. Reabra o terminal.
3. Valide:

```powershell
git --version
```

**Pronto quando**

- [ ] `git --version` retorna versão sem erro.

---

### Passo 2 — Configurar identidade Git

**Ação**

```powershell
git config --global user.name "Seu Nome"
git config --global user.email "seu.email@exemplo.com"
git config --global --get user.name
git config --global --get user.email
```

**Pronto quando**

- [ ] Nome e e-mail aparecem no `--get`.

---

### Passo 3 — Conta AWS + billing

**Ação**

1. Entre no **console AWS** com a região **us-east-1** (Norte da Virgínia) selecionada.
2. Ative MFA no **root**:
   - Clique no nome da conta (canto superior direito) > `Security credentials`
   - Em `Multi-factor authentication (MFA)` > `Assign MFA device`
   - Escolha `Authenticator app` (recomendado), escaneie o QR e confirme com 2 códigos
3. Em credenciais de segurança do root: não deixar Access Keys ativas.
   - Nome da conta (canto superior direito) > `Security credentials`
   - Abra `Access keys`
   - Se existir chave ativa no root: `Delete` (ou `Deactivate` e depois `Delete`)
   - Objetivo: root com **0 Access Keys**
4. Em `Billing`: confirmar budget/alertas.
   - No console AWS, abra o serviço **Billing** (faturamento / custos).
   - `Cost Explorer`: habilitar (se ainda não estiver ativo)
   - `Budgets` > `Create budget` > `Cost budget`
   - Defina valor mensal (ex.: 5 USD ou 20 USD)
   - Configure alertas por e-mail (ex.: 80% e 100%)

**Pronto quando**

- [ ] Console acessível em `us-east-1`.
- [ ] MFA ativo no root.
- [ ] Root sem Access Key.
- [ ] Budget criado.

---

### Passo 4 — Criar usuário IAM do laboratório

**Ação**

1. `IAM > Usuários > Criar usuário`
2. Nome: `cloud-reliability-lab`
3. Não marcar acesso ao console.
4. Em **Opções de permissões**, escolha **Adicionar usuário ao grupo**.
5. Selecione o grupo `Administrators` (conta pessoal de estudo).
6. Criar usuário.
7. No usuário criado: `Credenciais de segurança > Chaves de acesso > Criar chave`.
8. Tipo de uso: `CLI`.
9. Na tela final, copie `Access Key ID` + `Secret Access Key` e baixe o arquivo `.csv`.
10. Guarde o `.csv` em local seguro fora do repositório.
11. Depois de guardar com segurança, apague o `.csv` da pasta de Downloads.
12. Nunca colocar `Access Key ID`/`Secret Access Key` no GitHub, `README`, código ou `terraform.tfvars`.

**Pronto quando**

- [ ] Usuário IAM criado.
- [ ] Access Key criada e guardada com segurança.

---

### Passo 5 — Instalar AWS CLI e configurar credenciais

**Ação**

1. Instale a **AWS CLI v2** seguindo o guia oficial de instalação da AWS para o seu sistema.
2. Valide:

```powershell
aws --version
```

3. Configure:

```powershell
aws configure
```

Preencha:
- Access Key ID (do Passo 4)
- Secret Access Key (do Passo 4)
- Default region: `us-east-1`
- Default output format: `json`

4. Teste identidade:

```powershell
aws sts get-caller-identity
```

**Pronto quando**

- [ ] `aws --version` funciona.
- [ ] `aws sts get-caller-identity` retorna Account/UserArn sem erro.

---

### Passo 6 — Instalar Terraform

**Ação**

1. Instale o **Terraform** seguindo as instruções oficiais da HashiCorp para o seu sistema.
2. Reabra o terminal.
3. Valide:

```powershell
terraform version
```

**Pronto quando**

- [ ] `terraform version` funciona.

---

### Passo 7 — Conectar com GitHub (SSH) e remoto

**Ação**

1. Gerar chave SSH com senha (passphrase):

```powershell
ssh-keygen -t ed25519 -C "seu.email@exemplo.com"
```

Quando pedir no terminal (Git Bash):
- `Enter file in which to save the key (...)`: **aperte Enter** para aceitar o padrão (`~/.ssh/id_ed25519`).
- `Enter passphrase`: **digite sua senha da chave** (não aparece na tela, é normal).
- `Enter same passphrase again`: **digite a mesma senha novamente**.

2. Ver a chave pública para copiar:

```powershell
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

No Git Bash, pode usar:

```bash
cat ~/.ssh/id_ed25519.pub
```

3. Cadastrar no GitHub:
- GitHub > foto de perfil > `Settings`
- `SSH and GPG keys`
- `New SSH key`
- `Title`: ex. `Marlon-Windows`
- `Key type`: `Authentication Key`
- `Key`: cole o conteúdo do `.pub`
- `Add SSH key`

4. Testar autenticação SSH no GitHub:

```powershell
ssh -T git@github.com
```

5. Criar repositório remoto no GitHub (web):
- Nome: `cloud-reliability-lab`
- Visibilidade: `Public`
- Sem README/.gitignore/license iniciais

6. Se você **já está com este projeto aberto localmente** (pasta criada manualmente), configure o remoto:

```powershell
git remote add origin git@github.com:m4rlonalvesilva/cloud-reliability-lab.git
git remote -v
```

7. Se você quer **começar do zero clonando do GitHub** (em vez de usar uma pasta local já existente):

```powershell
cd C:\caminho\onde\quer\guardar
git clone git@github.com:m4rlonalvesilva/cloud-reliability-lab.git
cd cloud-reliability-lab
```

8. (Opcional agora, para quem começou local e ainda não subiu) Publicar no GitHub:

```powershell
git add .
git commit -m "feat: initialize cloud reliability lab"
git branch -M main
git push -u origin main
```

**Pronto quando**

- [ ] `ssh -T git@github.com` autentica.
- [ ] `git remote -v` mostra `origin` **ou** o repositório foi clonado com `git clone`.
- [ ] Chave SSH está protegida por passphrase.

---

### Passo 8 — Criar Key Pair EC2 (`.pem`)

**Ação**

1. No console AWS (`us-east-1`): `EC2 > Key Pairs > Create key pair`.
2. Nome sugerido: `cloud-reliability-lab-key`.
3. Tipo: RSA (ou ED25519, se preferir).
4. Baixar o `.pem` e guardar fora do repositório.
5. Formato recomendado para este projeto: **`.pem`** (Git Bash/PowerShell/OpenSSH).  
   Use **`.ppk`** apenas se você for usar PuTTY.

**Pronto quando**

- [ ] Key Pair criada na mesma região do lab.
- [ ] Arquivo `.pem` salvo com segurança.

---

### Passo 9 — MFA e sessão no terminal

**Objetivo:** neste terminal, credenciais AWS válidas para EC2 antes do Terraform (inclui contas que só liberam API com MFA na sessão).

**Ação**

1. **Console:** `IAM` → `Users` → `cloud-reliability-lab` → `Security credentials` → `Assign MFA device` → conclua (ex.: **Authenticator app**).

2. **Git Bash**, na **raiz** do repo — carregue o script com **`source`** (exporta variáveis neste shell; `./scripts/...` sozinho **não** funciona):

```bash
source ./scripts/aws-mfa-session.sh
```

3. **Testar:**

```bash
aws sts get-caller-identity
aws ec2 describe-availability-zones --region us-east-1
```

Se falhar: rode de novo `source ./scripts/aws-mfa-session.sh` (código MFA novo), confira `echo "$AWS_SESSION_TOKEN"` e se o usuário está no grupo certo em `IAM` → `Users` → `Groups`.

**Pronto quando**

- [ ] MFA aparece em `Security credentials` do usuário `cloud-reliability-lab`.
- [ ] `source ./scripts/aws-mfa-session.sh` conclui sem erro e você digitou o código MFA.
- [ ] Os dois comandos de teste acima funcionam neste terminal.

---

### Passo 10 — Preparar variáveis do Terraform

**Ação**

1. Descobrir seu IP público:

```bash
./scripts/get-my-public-ip.sh
```

Resumo dos scripts do lab: `scripts/README.md`.

2. Criar o arquivo local de variáveis:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars`:
- `aws_region = "us-east-1"`
- `ec2_key_name = "cloud-reliability-lab-key"` (ou seu nome real)
- `allow_ssh_cidrs = ["SEU_IP_PUBLICO/32"]`

**Pronto quando**

- [ ] `terraform.tfvars` preenchido.

---

### Passo 11 — Executar Terraform

**Ação**

Na pasta `terraform/`:

```powershell
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Digite `yes` no `apply`.

> **Erro 403 com `ForceMFA` / *explicit deny* no `terraform plan`:** o Terraform está usando credenciais **sem** MFA na sessão. No **mesmo** terminal (ex.: Git Bash): conclua o **Passo 9** com `source ./scripts/aws-mfa-session.sh`, confirme que `echo "$AWS_SESSION_TOKEN"` imprime algo, e rode novamente `terraform plan` na pasta `terraform/`.

No fim de um `apply` bem-sucedido, o próprio Terraform já imprime o bloco **Outputs:** no terminal (IPs, IDs, etc.). Não é obrigatório rodar `terraform output` a seguir — use só se quiser repetir essa listagem mais tarde.

**Pronto quando**

- [ ] `apply` conclui sem erro.
- [ ] No final do log do `apply` aparecem os **Outputs** com os IPs públicos (e demais valores esperados).

---

### Passo 12 — Validar ambiente criado

**Ação**

1. No console AWS: confirmar 2 EC2 `running`.
2. Testar SSH (use os IPs que apareceram em **Outputs** no fim do `apply` do Passo 11; se fechou o terminal, na pasta `terraform/` pode rodar `terraform output` para listar de novo):

```powershell
ssh -i "C:\caminho\cloud-reliability-lab-key.pem" ubuntu@IP_PUBLICO
```

**Pronto quando**

- [ ] EC2 visíveis e ativas no console.
- [ ] SSH conecta em pelo menos uma instância.

---

### Passo 13 — Encerrar lab e evitar custo

**Ação**

```powershell
cd terraform
terraform destroy
```

Digite `yes`.

**Pronto quando**

- [ ] Recursos removidos.
- [ ] Não há EC2 rodando no console.

---

### Passo 14 — Commit e push no GitHub

**Objetivo:** mandar para o **GitHub** o que mudou no lab. O **`.gitignore`** na raiz já impede `terraform.tfvars`, chaves `.pem`, estado do Terraform, pasta **`docs/`** pessoal, etc. — não precisa decorar a lista inteira; confie no arquivo e no `git status`.

**Ação** (na **raiz** do repositório, remoto `origin` do **Passo 7**):

```powershell
git status
```

Se na lista aparecer algo sensível (ex.: `terraform.tfvars`, `.pem`) como arquivo **novo** a ser commitado, pare e ajuste o `.gitignore` ou o caminho antes de seguir.

```powershell
git add .
git commit -m "chore: atualiza lab após destroy"
git push
```

Pode mudar a mensagem do `commit`. Se não houver alterações, o Git diz que não há nada a commitar — é normal.

**Prefixos de commit (Conventional Commits)** — padrão opcional `tipo: descrição` curta em inglês ou português:

| Prefixo | Quando usar |
|---------|-------------|
| `feat:` | Nova funcionalidade ou recurso (ex.: novo módulo Terraform). |
| `fix:` | Correção de bug ou de comportamento incorreto. |
| `docs:` | Só documentação (`README`, guias, comentários de doc). |
| `chore:` | Manutenção sem mudar o que o sistema “faz” (`.gitignore`, formatação, ajustes de tooling, fecho de lab no Git). |
| `refactor:` | Refatoração de código sem mudar comportamento visível. |
| `perf:` | Melhoria de desempenho. |
| `test:` | Inclusão ou alteração de testes. |
| `ci:` | Pipelines de CI/CD (GitHub Actions, etc.). |

O exemplo `chore: atualiza lab após destroy` indica commit de **rotina** após encerrar a infra, não uma feature nova.

**Pronto quando**

- [ ] `git push` terminou sem erro e o commit aparece no GitHub.
- [ ] No remoto não entrou `terraform.tfvars`, `.pem` nem outro segredo.

---

### Passo opcional — Extensão Terraform/HCL na IDE de sua preferência

No marketplace de extensões da sua IDE (por exemplo **Cursor**, **VS Code**, **JetBrains**), instale a extensão **HashiCorp Terraform** ou equivalente com suporte a **HCL**, para realce de sintaxe, formatação e navegação nos arquivos `.tf`.

**Pronto quando**

- [ ] Arquivos `.tf` abrem com realce e formatação úteis no editor.

---

