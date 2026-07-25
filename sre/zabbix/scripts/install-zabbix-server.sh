#!/usr/bin/env bash
# Instala Zabbix Server 6.4.0 + Frontend (Apache) + PostgreSQL + Agent2 (Ubuntu 22.04).
# Uso: cloud-init / user_data na EC2 Role=zabbix-server.
# Lab only: passwords fixas documentadas em sre/zabbix/ACCESS.md — alterar após o 1.º login.
set -euo pipefail

exec > >(tee /var/log/zabbix-bootstrap.log | logger -t zabbix-bootstrap -s 2>/dev/console) 2>&1

STATUS_DIR=/var/lib/cloud-reliability-lab
STATUS_FILE="${STATUS_DIR}/zabbix-bootstrap.status"
# Credenciais só para laboratório (SG restrito). Não reutilizar em produção.
DB_PASSWORD='LabZabbixDB'
ZBX_SERVER_NAME='cloud-reliability-lab'
PHP_TIMEZONE='America/Sao_Paulo'
# Versão exata pedida para o lab
ZBX_VERSION='6.4.0'
ZBX_PKG_VER="1:${ZBX_VERSION}-1+ubuntu22.04"

mark_status() {
  sudo mkdir -p "$STATUS_DIR"
  echo "$1 $(date -u +%Y-%m-%dT%H:%M:%SZ)" | sudo tee "$STATUS_FILE" >/dev/null
}

if [[ -f "$STATUS_FILE" ]] && grep -q "^ready ${ZBX_VERSION}" "$STATUS_FILE"; then
  echo "[zabbix] Já instalado (status ready ${ZBX_VERSION}). A sair."
  exit 0
fi

mark_status "starting-${ZBX_VERSION}"
echo "[zabbix] Início da instalação Zabbix ${ZBX_VERSION} (PostgreSQL + Apache)"

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get install -y ca-certificates curl wget gnupg apache2

. /etc/os-release
if [[ "${VERSION_ID:-}" != "22.04" ]]; then
  echo "[zabbix] AVISO: script validado em Ubuntu 22.04; detetado ${VERSION_ID:-desconhecido}"
fi

# --- Repositório oficial Zabbix 6.4 (Ubuntu 22.04 jammy) ---
RELEASE_DEB="zabbix-release_latest_6.4+ubuntu22.04_all.deb"
RELEASE_DEB_FALLBACK="zabbix-release_6.4-1+ubuntu22.04_all.deb"
RELEASE_BASE="https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release"
cd /tmp
# Remover release antigo (ex.: 7.0) se existir
sudo apt-get remove -y zabbix-release 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/zabbix.list /etc/apt/sources.list.d/zabbix*.list 2>/dev/null || true

if wget -q -O "$RELEASE_DEB" "${RELEASE_BASE}/${RELEASE_DEB}"; then
  sudo dpkg -i "$RELEASE_DEB"
elif wget -q -O "$RELEASE_DEB_FALLBACK" "${RELEASE_BASE}/${RELEASE_DEB_FALLBACK}"; then
  sudo dpkg -i "$RELEASE_DEB_FALLBACK"
else
  echo "[zabbix] ERRO: não foi possível descarregar o pacote zabbix-release 6.4"
  mark_status "failed-repo"
  exit 1
fi
sudo apt-get update -y

# --- PostgreSQL ---
sudo apt-get install -y postgresql

# --- Pacotes Zabbix 6.4.0 (versão pinada) ---
# php-pgsql é obrigatório para a UI aceitar POSTGRESQL
sudo apt-get install -y \
  "zabbix-server-pgsql=${ZBX_PKG_VER}" \
  "zabbix-frontend-php=${ZBX_PKG_VER}" \
  "zabbix-apache-conf=${ZBX_PKG_VER}" \
  "zabbix-sql-scripts=${ZBX_PKG_VER}" \
  "zabbix-agent2=${ZBX_PKG_VER}" \
  php-pgsql \
  php-mbstring \
  php-gd \
  php-xml \
  php-bcmath \
  php-ldap \
  php-curl

# Evitar upgrade acidental para outra minor
sudo apt-mark hold \
  zabbix-server-pgsql \
  zabbix-frontend-php \
  zabbix-apache-conf \
  zabbix-sql-scripts \
  zabbix-agent2 || true

# --- Base de dados ---
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='zabbix'" | grep -q 1; then
  sudo -u postgres psql -c "CREATE USER zabbix WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';"
fi
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='zabbix'" | grep -q 1; then
  sudo -u postgres createdb -O zabbix -E Unicode -T template0 zabbix
fi

TABLE_COUNT="$(sudo -u postgres psql -d zabbix -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'" | tr -d '[:space:]')"
if [[ "${TABLE_COUNT:-0}" == "0" ]]; then
  echo "[zabbix] A importar schema SQL…"
  zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
else
  echo "[zabbix] Schema já presente (${TABLE_COUNT} tabelas) — skip import"
fi

# --- zabbix_server.conf ---
if grep -qE '^#?\s*DBPassword=' /etc/zabbix/zabbix_server.conf; then
  sudo sed -i -E "s/^#?\s*DBPassword=.*/DBPassword=${DB_PASSWORD}/" /etc/zabbix/zabbix_server.conf
else
  echo "DBPassword=${DB_PASSWORD}" | sudo tee -a /etc/zabbix/zabbix_server.conf >/dev/null
fi
if grep -qE '^#?\s*DBHost=' /etc/zabbix/zabbix_server.conf; then
  sudo sed -i -E "s/^#?\s*DBHost=.*/DBHost=localhost/" /etc/zabbix/zabbix_server.conf
else
  echo "DBHost=localhost" | sudo tee -a /etc/zabbix/zabbix_server.conf >/dev/null
fi

# --- PHP timezone (Apache) ---
if [[ -f /etc/zabbix/apache.conf ]]; then
  sudo sed -i "s|#\\s*php_value date.timezone .*|php_value date.timezone ${PHP_TIMEZONE}|" /etc/zabbix/apache.conf
  if ! grep -q "php_value date.timezone" /etc/zabbix/apache.conf; then
    echo "php_value date.timezone ${PHP_TIMEZONE}" | sudo tee -a /etc/zabbix/apache.conf >/dev/null
  fi
fi

# --- Frontend sem wizard ---
sudo mkdir -p /etc/zabbix/web
sudo tee /etc/zabbix/web/zabbix.conf.php >/dev/null <<EOF
<?php
// Gerado pelo bootstrap do cloud-reliability-lab (lab only) — Zabbix ${ZBX_VERSION}.
\$DB['TYPE']     = 'POSTGRESQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '5432';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '${DB_PASSWORD}';
\$DB['SCHEMA']   = '';
\$DB['ENCRYPTION'] = false;
\$DB['KEY_FILE'] = '';
\$DB['CERT_FILE'] = '';
\$DB['CA_FILE'] = '';
\$DB['VERIFY_HOST'] = false;
\$DB['CIPHER_LIST'] = '';
\$DB['VAULT'] = '';
\$DB['VAULT_URL'] = '';
\$DB['VAULT_PREFIX'] = '';
\$DB['VAULT_DB_PATH'] = '';
\$DB['VAULT_CERT_FILE'] = '';
\$DB['VAULT_KEY_FILE'] = '';
\$DB['VAULT_CACHE'] = false;
\$DB['DOUBLE_IEEE754'] = true;
\$ZBX_SERVER = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '${ZBX_SERVER_NAME}';
\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF
sudo chown www-data:www-data /etc/zabbix/web/zabbix.conf.php
sudo chmod 640 /etc/zabbix/web/zabbix.conf.php

# Agent local aponta para o próprio server
sudo sed -i 's/^Server=.*/Server=127.0.0.1/' /etc/zabbix/zabbix_agent2.conf
sudo sed -i 's/^ServerActive=.*/ServerActive=127.0.0.1/' /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^Hostname=.*/Hostname=Zabbix server/" /etc/zabbix/zabbix_agent2.conf
if ! grep -q '^Hostname=' /etc/zabbix/zabbix_agent2.conf; then
  echo "Hostname=Zabbix server" | sudo tee -a /etc/zabbix/zabbix_agent2.conf >/dev/null
fi

sudo systemctl enable zabbix-server zabbix-agent2 apache2
sudo systemctl restart postgresql
sudo systemctl restart zabbix-server
sudo systemctl restart zabbix-agent2
sudo systemctl restart apache2

sleep 3
if ! systemctl is-active --quiet zabbix-server; then
  echo "[zabbix] ERRO: zabbix-server não está active"
  sudo systemctl status zabbix-server --no-pager || true
  sudo tail -50 /var/log/zabbix/zabbix_server.log || true
  mark_status "failed-server"
  exit 1
fi
if ! systemctl is-active --quiet apache2; then
  echo "[zabbix] ERRO: apache2 não está active"
  mark_status "failed-apache"
  exit 1
fi

INSTALLED_VER="$(dpkg-query -W -f='${Version}' zabbix-server-pgsql 2>/dev/null || true)"
echo "[zabbix] Pacote instalado: zabbix-server-pgsql ${INSTALLED_VER}"

HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/zabbix/ || true)"
echo "[zabbix] HTTP local /zabbix/ → ${HTTP_CODE}"
if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "301" && "$HTTP_CODE" != "302" ]]; then
  echo "[zabbix] AVISO: UI ainda não respondeu 200 (código ${HTTP_CODE}); ver logs Apache/PHP"
fi

mark_status "ready ${ZBX_VERSION}"
echo "[zabbix] Instalação concluída — Zabbix ${ZBX_VERSION}."
echo "[zabbix] UI: http://<IP_PUBLICO>/zabbix  |  Admin / zabbix  (alterar password)"
echo "[zabbix] Detalhes: sre/zabbix/ACCESS.md"
