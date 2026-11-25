#!/usr/bin/env bash
# Restringe a aplicação à rede OpenVPN e publica uma rota privada da Frontend.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute com sudo: sudo bash enable-vpn-only.sh IP_PRIVADO_FRONTEND IP_PRIVADO_BACKEND IP_PUBLICO_FRONTEND [VPN_CIDR]" >&2
  exit 1
fi

FRONTEND_PRIVATE_IP="${1:-}"
BACKEND_PRIVATE_IP="${2:-}"
FRONTEND_PUBLIC_IP="${3:-}"
VPN_CIDR="${4:-10.8.0.0/24}"
WEBROOT="/var/www/dadoseguro"
SITE="/etc/nginx/sites-available/dadosseguro"
VPN_CONFIG="/etc/openvpn/server.conf"
CERT_DIR="/etc/letsencrypt/live/dado-seguro-ip"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
SITE_BACKUP="${SITE}.before-vpn-only-${TIMESTAMP}"
VPN_BACKUP="${VPN_CONFIG}.before-vpn-only-${TIMESTAMP}"
VPN_ROUTE="push \"route ${FRONTEND_PRIVATE_IP} 255.255.255.255\""

for address in "${FRONTEND_PRIVATE_IP}" "${BACKEND_PRIVATE_IP}" "${FRONTEND_PUBLIC_IP}"; do
  if [[ ! "${address}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    echo "Informe os IPv4 privado da Frontend, privado do Backend e público da Frontend." >&2
    exit 1
  fi
done
if [[ ! "${VPN_CIDR}" =~ ^10\.8\.0\.0/24$ ]]; then
  echo "A configuração OpenVPN ativa usa 10.8.0.0/24; ajuste o servidor e este script juntos para outra faixa." >&2
  exit 1
fi
if [[ ! -s "${SITE}" || ! -s "${VPN_CONFIG}" || ! -s "${WEBROOT}/index.html" ]]; then
  echo "Nginx, OpenVPN ou frontend não foram encontrados nos caminhos esperados." >&2
  exit 1
fi
if [[ ! -s "${CERT_DIR}/fullchain.pem" || ! -s "${CERT_DIR}/privkey.pem" ]]; then
  echo "Certificado HTTPS para o IP público não encontrado; configure HTTPS antes." >&2
  exit 1
fi
if ! grep -Eq '^server[[:space:]]+10\.8\.0\.0[[:space:]]+255\.255\.255\.0([[:space:]]|$)' "${VPN_CONFIG}"; then
  echo "O pool de clientes do OpenVPN não corresponde a 10.8.0.0/24." >&2
  exit 1
fi
if ! systemctl is-active --quiet openvpn@server; then
  echo "O servidor ativo openvpn@server não está em execução." >&2
  exit 1
fi

ACTIVE_CLIENTS="$(awk -F, '$1 == "CLIENT_LIST" { count++ } END { print count + 0 }' /run/openvpn/server.status 2>/dev/null || echo 0)"
cp -a "${SITE}" "${SITE_BACKUP}"
cp -a "${VPN_CONFIG}" "${VPN_BACKUP}"

if ! grep -Fqx "${VPN_ROUTE}" "${VPN_CONFIG}"; then
  printf '\n# Dado Seguro: rota da Frontend para acesso privado pela VPN.\n%s\n' "${VPN_ROUTE}" >> "${VPN_CONFIG}"
fi

cat > "${SITE}" <<NGINX
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
        proxy_pass http://${BACKEND_PRIVATE_IP}/api/;
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
    server_name ${FRONTEND_PUBLIC_IP};
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
        proxy_pass http://${BACKEND_PRIVATE_IP}/api/;
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
  cp -a "${SITE_BACKUP}" "${SITE}"
  cp -a "${VPN_BACKUP}" "${VPN_CONFIG}"
  exit 1
fi

if ! systemctl restart openvpn@server; then
  cp -a "${SITE_BACKUP}" "${SITE}"
  cp -a "${VPN_BACKUP}" "${VPN_CONFIG}"
  systemctl restart openvpn@server || true
  nginx -t && systemctl reload nginx || true
  exit 1
fi

if ! systemctl reload nginx; then
  cp -a "${SITE_BACKUP}" "${SITE}"
  cp -a "${VPN_BACKUP}" "${VPN_CONFIG}"
  systemctl restart openvpn@server || true
  nginx -t && systemctl reload nginx || true
  exit 1
fi

echo "Aplicação disponível somente aos clientes ${VPN_CIDR}."
echo "Pela VPN, abra http://${FRONTEND_PRIVATE_IP}; o tráfego HTTP fica protegido pelo túnel OpenVPN."
echo "Acesso público direto ao IP da Frontend retorna 403 (fora da validação ACME)."
echo "OpenVPN reiniciado; clientes precisam reconectar para receber a rota ${FRONTEND_PRIVATE_IP}/32. Clientes antes conectados: ${ACTIVE_CLIENTS}."
