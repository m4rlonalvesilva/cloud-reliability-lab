#!/usr/bin/env bash
# Carrega credenciais temporarias (STS) com MFA no shell ATUAL.
# Uso (Git Bash), na raiz do repositorio:
#   source ./scripts/aws-mfa-session.sh
#
# Variaveis opcionais:
#   AWS_MFA_USER        (padrao: cloud-reliability-lab)
#   AWS_DEFAULT_REGION  (padrao: us-east-1)
#   AWS_MFA_DURATION    (padrao: 43200 = 12h)

# Nao use "set -euo pipefail" aqui: este arquivo e carregado com "source"
# no shell interativo, e essas opcoes podem encerrar o Git Bash ao primeiro erro.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Este script precisa ser carregado com source para exportar as variaveis no seu shell:" >&2
  echo "  source ./scripts/aws-mfa-session.sh" >&2
  exit 1
fi

IAM_USER="${AWS_MFA_USER:-cloud-reliability-lab}"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
DURATION="${AWS_MFA_DURATION:-43200}"

aws_cli=(aws)
if [[ -n "${AWS_PROFILE:-}" ]]; then
  aws_cli=(aws --profile "${AWS_PROFILE}")
fi

SERIAL="$("${aws_cli[@]}" iam list-mfa-devices \
  --user-name "${IAM_USER}" \
  --query 'MFADevices[0].SerialNumber' \
  --output text)"

if [[ -z "${SERIAL}" || "${SERIAL}" == "None" ]]; then
  echo "Nenhum MFA encontrado para o usuario '${IAM_USER}'." >&2
  echo "Associe MFA em: IAM > Users > ${IAM_USER} > Security credentials > Assign MFA device" >&2
  return 1 2>/dev/null || exit 1
fi

echo "Serial MFA detectado: ${SERIAL}" >&2
read -r -p "Digite o codigo MFA (6 digitos): " TOKEN
TOKEN="${TOKEN//[[:space:]]/}"

if [[ ! "${TOKEN}" =~ ^[0-9]{6}$ ]]; then
  echo "Codigo MFA invalido (esperado 6 digitos)." >&2
  return 1 2>/dev/null || exit 1
fi

IFS=$'\t' read -r AK SK ST <<< "$("${aws_cli[@]}" sts get-session-token \
  --serial-number "${SERIAL}" \
  --token-code "${TOKEN}" \
  --duration-seconds "${DURATION}" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)"

if [[ -z "${AK}" || -z "${SK}" || -z "${ST}" ]]; then
  echo "Falha ao obter credenciais temporarias (STS)." >&2
  return 1 2>/dev/null || exit 1
fi

export AWS_ACCESS_KEY_ID="${AK}"
export AWS_SECRET_ACCESS_KEY="${SK}"
export AWS_SESSION_TOKEN="${ST}"
export AWS_DEFAULT_REGION="${AWS_REGION}"

echo "Sessao MFA carregada neste shell (AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION})." >&2
echo "Teste: aws sts get-caller-identity" >&2
