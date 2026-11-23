#!/usr/bin/env bash
# Enable the API overlay after backend/ and deploy/compose.application.yaml
# have been copied to /opt/dado-seguro.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute com: sudo bash enable-api.sh" >&2
  exit 1
fi

APP_DIR="/opt/dado-seguro"
BASE_COMPOSE="${APP_DIR}/compose.yaml"
APP_COMPOSE="${APP_DIR}/deploy/compose.application.yaml"
if [[ ! -s "${BASE_COMPOSE}" || ! -s "${APP_COMPOSE}" || ! -s "${APP_DIR}/backend/dist/server.js" ]]; then
  echo "Copie backend/ compilado e deploy/compose.application.yaml para ${APP_DIR} antes de continuar." >&2
  exit 1
fi

install -d -m 0700 "${APP_DIR}"
umask 077
for secret_file in "${APP_DIR}/.admin_password" "${APP_DIR}/.session_secret"; do
  if [[ ! -f "${secret_file}" ]]; then
    openssl rand -hex 32 > "${secret_file}"
  fi
  chmod 0644 "${secret_file}"
done
chmod 0644 "${APP_DIR}/.db_password"

cd "${APP_DIR}"
docker compose -f "${BASE_COMPOSE}" -f "${APP_COMPOSE}" config --quiet
docker compose -f "${BASE_COMPOSE}" -f "${APP_COMPOSE}" up -d --build --wait api
curl -fsS http://127.0.0.1:3000/healthz
echo
docker compose -f "${BASE_COMPOSE}" -f "${APP_COMPOSE}" ps api
echo "Admin inicial: admin. Senha temporária em ${APP_DIR}/.admin_password (copie para local seguro)."
