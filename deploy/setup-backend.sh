#!/usr/bin/env bash
# Instala Docker Compose e inicia PostgreSQL para o laboratório Dado Seguro.
# Ubuntu 22.04, 24.04 ou 26.04. Não publica a porta do banco no host.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute com privilégios administrativos: sudo bash setup-backend.sh" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Não foi possível identificar a distribuição Linux." >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" || ! " ${VERSION_ID:-} " =~ [[:space:]](22\.04|24\.04|26\.04)[[:space:]] ]]; then
  echo "Este script suporta Ubuntu 22.04, 24.04 e 26.04." >&2
  exit 1
fi

if command -v docker >/dev/null 2>&1; then
  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker já existe, mas Docker Compose não está disponível. Revise a instalação atual antes de continuar." >&2
    exit 1
  fi
else
  apt-get update
  apt-get install -y ca-certificates curl openssl

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  if [[ -z "${CODENAME}" ]]; then
    echo "Não foi possível determinar o codinome do Ubuntu." >&2
    exit 1
  fi

  ARCH="$(dpkg --print-architecture)"
  cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
fi

systemctl enable --now docker

APP_DIR="/opt/dado-seguro"
COMPOSE_FILE="${APP_DIR}/compose.yaml"
DB_SECRET="${APP_DIR}/.db_password"
ADMIN_SECRET="${APP_DIR}/.admin_password"
SESSION_SECRET="${APP_DIR}/.session_secret"
install -d -m 0700 "${APP_DIR}"
umask 077

for secret_file in "${DB_SECRET}" "${ADMIN_SECRET}" "${SESSION_SECRET}"; do
  if [[ ! -f "${secret_file}" ]]; then
    openssl rand -hex 32 > "${secret_file}"
  fi
  # The parent directory is root-only; mounted Compose secrets must be
  # readable by the non-root API container.
  chmod 0644 "${secret_file}"
done

if [[ -e "${COMPOSE_FILE}" ]]; then
  if ! grep -q 'DADOSEGURO_MANAGED_POSTGRES' "${COMPOSE_FILE}"; then
    echo "${COMPOSE_FILE} já existe e não foi criado por este script; não será sobrescrito." >&2
    exit 1
  fi
else
  cat > "${COMPOSE_FILE}" <<'YAML'
# DADOSEGURO_MANAGED_POSTGRES
services:
  db:
    image: postgres:16
    container_name: dado-seguro-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: dadoseguro
      POSTGRES_USER: dadoseguro_app
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    shm_size: 128mb
    mem_limit: 384m
    cpus: 0.5
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \"$${POSTGRES_USER}\" -d \"$${POSTGRES_DB}\""]
      interval: 10s
      timeout: 5s
      retries: 5

secrets:
  db_password:
    file: ./.db_password

volumes:
  postgres_data:
YAML
  chmod 0600 "${COMPOSE_FILE}"
fi

cd "${APP_DIR}"
docker compose pull db
docker compose up -d --wait db
docker compose exec -T db pg_isready -U dadoseguro_app -d dadoseguro
docker compose ps

echo "PostgreSQL está ativo em um volume persistente do Docker."
echo "A porta 5432 não foi publicada no host; serviços no mesmo Compose usam db:5432."
