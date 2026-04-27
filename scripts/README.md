# Scripts

Utilitários do laboratório (Fase 1).

| Script | Descrição |
|--------|-----------|
| `get-my-public-ip.sh` | Exibe seu IPv4 público no formato `x.x.x.x/32` para preencher `allow_ssh_cidrs` no Terraform (Git Bash). |
| `get-my-public-ip.ps1` | Exibe seu IPv4 público no formato `x.x.x.x/32` para preencher `allow_ssh_cidrs` no Terraform (PowerShell). |
| `aws-mfa-session.sh` | Sessão STS com MFA: pede o código de 6 dígitos e exporta as variáveis `AWS_*` no shell atual. Uso: `source ./scripts/aws-mfa-session.sh` (Passo 9 do README). |

Execute no Git Bash a partir da raiz do repositório:

```bash
./scripts/get-my-public-ip.sh
```

Ou no PowerShell:

```powershell
.\scripts\get-my-public-ip.ps1
```
