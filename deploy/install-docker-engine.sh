#!/usr/bin/env bash
# Instala Docker Engine e o plugin Docker Compose pelo repositório oficial.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute como root: sudo bash install-docker-engine.sh" >&2
  exit 1
fi

if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    systemctl enable --now docker
    echo "Docker Engine e Compose já estavam instalados e ativos."
    exit 0
  fi
  echo "Docker já existe sem Docker Compose; revise a instalação antes de continuar." >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != ubuntu || ! " ${VERSION_ID:-} " =~ [[:space:]](22\.04|24\.04|26\.04)[[:space:]] ]]; then
  echo "Este instalador suporta Ubuntu 22.04, 24.04 e 26.04." >&2
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
systemctl enable --now docker
docker compose version
echo "Docker Engine e Docker Compose instalados pelo repositório oficial."
