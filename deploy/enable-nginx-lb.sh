#!/usr/bin/env bash
# Ativa Nginx round-robin e failover após validar os três proxies de API.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute como root: sudo bash enable-nginx-lb.sh IP_BACKEND1 IP_BACKEND2 IP_BACKUP [VPN_CIDR]" >&2
  exit 1
fi

BACKEND1="${1:-}"
BACKEND2="${2:-}"
BACKUP="${3:-}"
VPN_CIDR="${4:-10.8.0.0/24}"
SITE="/etc/nginx/sites-available/dadosseguro"
WEBROOT="/var/www/dadoseguro"
CERT_DIR="/etc/letsencrypt/live/dado-seguro-ip"

for address in "${BACKEND1}" "${BACKEND2}" "${BACKUP}"; do
  if [[ ! "${address}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    echo "Informe os três IPv4 privados das instâncias." >&2
    exit 1
  fi
done
if [[ ! -s "${SITE}" || ! -s "${WEBROOT}/index.html" ]]; then
  echo "Nginx do frontend ou build da aplicação não encontrado." >&2
  exit 1
fi

# Não troca a configuração antes de confirmar que cada destino responde.
for address in "${BACKEND1}" "${BACKEND2}" "${BACKUP}"; do
  code="$(curl --silent --output /dev/null --write-out '%{http_code}' \
    --max-time 4 -H 'Host: api.dadoseguro.internal' \
    "http://${address}/api/healthz" || true)"
  if [[ "${code}" != "200" ]]; then
    echo "Backend ${address} não passou no health check (HTTP ${code}); configuração atual mantida." >&2
    exit 1
  fi
done

timestamp="$(date +%Y%m%d%H%M%S)"
cp -a "${SITE}" "${SITE}.before-lb-${timestamp}"
cat > "${SITE}" <<NGINX
upstream dadoseguro_api {
    server ${BACKEND1}:80 max_fails=2 fail_timeout=5s;
    server ${BACKEND2}:80 max_fails=2 fail_timeout=5s;
    server ${BACKUP}:80 backup;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root ${WEBROOT};
    index index.html;
    client_max_body_size 26m;
    allow ${VPN_CIDR};
    deny all;

    location ^~ /.well-known/acme-challenge/ {
        allow all;
        root ${WEBROOT};
        default_type text/plain;
        try_files \$uri =404;
    }
    location /api/ {
        proxy_pass http://dadoseguro_api/api/;
        proxy_http_version 1.1;
        proxy_set_header Host api.dadoseguro.internal;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;
    root ${WEBROOT};
    index index.html;
    client_max_body_size 26m;
    allow ${VPN_CIDR};
    deny all;
    ssl_certificate ${CERT_DIR}/fullchain.pem;
    ssl_certificate_key ${CERT_DIR}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    location /api/ {
        proxy_pass http://dadoseguro_api/api/;
        proxy_http_version 1.1;
        proxy_set_header Host api.dadoseguro.internal;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_read_timeout 60s;
    }
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
NGINX

if ! nginx -t; then
  cp -a "${SITE}.before-lb-${timestamp}" "${SITE}"
  exit 1
fi
if ! systemctl reload nginx; then
  cp -a "${SITE}.before-lb-${timestamp}" "${SITE}"
  nginx -t && systemctl reload nginx || true
  exit 1
fi
echo "Nginx round-robin ativo para Backend 1 e 2; Backup configurado como reserva."
echo "O site continua restrito à VPN ${VPN_CIDR}; HTTP e HTTPS preservados."
