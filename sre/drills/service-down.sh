#!/usr/bin/env bash
# App fictícia systemd (crl-lab-app) — instalar / parar / restaurar.
# Uso: sudo bash service-down.sh {install|start|restore|status}
set -euo pipefail
UNIT=/etc/systemd/system/crl-lab-app.service
PORT=8089

install_unit() {
  if [[ ! -f "$UNIT" ]]; then
    cat >"$UNIT" <<EOF
[Unit]
Description=CRL lab demo app (HTTP :${PORT})
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server ${PORT} --bind 127.0.0.1
WorkingDirectory=/tmp
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now crl-lab-app
    echo "[drill] Unit instalada e a correr (porta ${PORT})"
  else
    echo "[drill] Unit já existe"
    systemctl enable --now crl-lab-app
  fi
  systemctl status crl-lab-app --no-pager || true
}

cmd="${1:-}"
case "$cmd" in
  install) install_unit ;;
  start)
    install_unit
    echo "[drill] A PARAR crl-lab-app (incidente serviço down)"
    systemctl stop crl-lab-app
    systemctl status crl-lab-app --no-pager || true
    echo "[drill] Depois: sudo bash $0 restore"
    ;;
  restore)
    install_unit
    systemctl start crl-lab-app
    systemctl status crl-lab-app --no-pager
    curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://127.0.0.1:${PORT}/" || true
    ;;
  status)
    systemctl status crl-lab-app --no-pager || true
    ;;
  *) echo "Uso: sudo bash $0 {install|start|restore|status}" >&2; exit 1 ;;
esac
