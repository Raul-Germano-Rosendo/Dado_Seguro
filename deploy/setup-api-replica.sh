#!/usr/bin/env bash
# Prepara API em nó secundário sem criar outro PostgreSQL divergente.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute como root: sudo bash setup-api-replica.sh IP_PRIVADO_POSTGRES" >&2
  exit 1
fi

DB_HOST="${1:-}"
APP_DIR="/opt/dado-seguro"
COMPOSE="${APP_DIR}/deploy/compose.replica.yaml"
if [[ ! "${DB_HOST}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo "Informe o IP privado da Backend 1 que executa o PostgreSQL." >&2
  exit 1
fi
for path in "${APP_DIR}/backend/Dockerfile" "${APP_DIR}/backend/src/server.ts" \
  "${APP_DIR}/deploy/compose.replica.yaml" "${APP_DIR}/deploy/nginx-backend-api.conf.example"; do
  [[ -s "${path}" ]] || { echo "Arquivo necessário ausente: ${path}" >&2; exit 1; }
done
for secret in .db_password .admin_password .session_secret; do
  [[ -s "${APP_DIR}/${secret}" ]] || {
    echo "Transfira ${secret} da Backend 1 por um canal SSH seguro antes de iniciar." >&2
    exit 1
  }
  chmod 0644 "${APP_DIR}/${secret}"
done

if ! command -v docker >/dev/null 2>&1; then
  . /etc/os-release
  if [[ "${ID:-}" != ubuntu ]]; then
    echo "Este instalador de Docker suporta Ubuntu." >&2
    exit 1
  fi
  apt-get update
  apt-get install -y ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-${VERSION_CODENAME}}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
docker compose version >/dev/null
systemctl enable --now docker
if ! command -v nginx >/dev/null 2>&1 || ! systemctl is-active --quiet nginx; then
  echo "Nginx precisa estar instalado e ativo no nó replica." >&2
  exit 1
fi

printf 'DADOSEGURO_DB_HOST=%s\n' "${DB_HOST}" > "${APP_DIR}/.env"
chmod 0600 "${APP_DIR}/.env"
install -m 0644 "${APP_DIR}/deploy/nginx-backend-api.conf.example" \
  /etc/nginx/sites-available/dado-seguro-api
ln -sfn /etc/nginx/sites-available/dado-seguro-api /etc/nginx/sites-enabled/dado-seguro-api

cd "${APP_DIR}"
docker compose --env-file .env -f deploy/compose.replica.yaml config --quiet
docker compose --env-file .env -f deploy/compose.replica.yaml up -d --build --wait
nginx -t
systemctl reload nginx
curl -fsS -H 'Host: api.dadoseguro.internal' http://127.0.0.1/api/healthz
echo
docker compose --env-file .env -f deploy/compose.replica.yaml ps
echo "API replica pronta. Ela usa o PostgreSQL remoto e não inicia banco local."
