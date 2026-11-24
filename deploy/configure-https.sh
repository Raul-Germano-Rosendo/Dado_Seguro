#!/usr/bin/env bash
# Emite um certificado IP Let's Encrypt e ativa HTTPS no Nginx do frontend.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
	echo "Execute com sudo: sudo bash configure-https.sh IP_PRIVADO_BACKEND IP_PUBLICO_FRONTEND [VPN_CIDR]" >&2
  exit 1
fi

BACKEND_PRIVATE_IP="${1:-}"
FRONTEND_PUBLIC_IP="${2:-}"
VPN_CIDR="${3:-10.8.0.0/24}"
if [[ ! "${BACKEND_PRIVATE_IP}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ || ! "${FRONTEND_PUBLIC_IP}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo "Informe o IPv4 privado do Backend e o IPv4 público do Frontend." >&2
  exit 1
fi
if [[ ! "${VPN_CIDR}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
  echo "Informe a faixa CIDR usada pelos clientes OpenVPN (ex.: 10.8.0.0/24)." >&2
  exit 1
fi
if [[ ! -s /var/www/dadoseguro/index.html ]]; then
  echo "Frontend não encontrado em /var/www/dadoseguro; publique o build antes." >&2
  exit 1
fi

WEBROOT="/var/www/dadoseguro"
CERT_NAME="dado-seguro-ip"
CERT_DIR="/etc/letsencrypt/live/${CERT_NAME}"
SITE="/etc/nginx/sites-available/dadosseguro"
BACKUP="${SITE}.before-dado-seguro-https"

apt-get update
apt-get install -y snapd
systemctl enable --now snapd.socket
snap wait system seed.loaded
if ! snap list certbot >/dev/null 2>&1; then
  snap install --classic certbot
fi
ln -sfn /snap/bin/certbot /usr/local/bin/certbot

if [[ ! -e "${BACKUP}" ]]; then
  cp -a "${SITE}" "${BACKUP}"
fi

CERTBOT_VERSION="$(certbot --version 2>&1 | awk '{print $2}')"
if ! dpkg --compare-versions "${CERTBOT_VERSION}" ge 5.4; then
  echo "Certbot ${CERTBOT_VERSION} não oferece certificado IP por webroot; é necessário >= 5.4." >&2
  exit 1
fi

if [[ ! -s "${CERT_DIR}/fullchain.pem" || ! -s "${CERT_DIR}/privkey.pem" ]]; then
  cat > "${SITE}" <<NGINX_HTTP
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${FRONTEND_PUBLIC_IP};
    root ${WEBROOT};
    index index.html;
    allow ${VPN_CIDR};
    deny all;
    client_max_body_size 26m;

    location ^~ /.well-known/acme-challenge/ {
        allow all;
        root ${WEBROOT};
        default_type text/plain;
        try_files \$uri =404;
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
NGINX_HTTP

  nginx -t
  systemctl reload nginx
  certbot certonly --non-interactive --agree-tos --register-unsafely-without-email \
    --preferred-profile shortlived --webroot --webroot-path "${WEBROOT}" \
    --ip-address "${FRONTEND_PUBLIC_IP}" --cert-name "${CERT_NAME}"
fi

install -d -m 0755 /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/10-dado-seguro-nginx <<'HOOK'
#!/bin/sh
set -eu
/usr/bin/systemctl reload nginx
HOOK
chmod 0755 /etc/letsencrypt/renewal-hooks/deploy/10-dado-seguro-nginx

cat > "${SITE}" <<NGINX_TLS
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${FRONTEND_PUBLIC_IP};
    root ${WEBROOT};
    client_max_body_size 26m;
    allow ${VPN_CIDR};
    deny all;

    location ^~ /.well-known/acme-challenge/ {
        allow all;
        root ${WEBROOT};
        default_type text/plain;
        try_files \$uri =404;
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
    allow ${VPN_CIDR};
    deny all;
    client_max_body_size 26m;

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
NGINX_TLS

nginx -t
systemctl reload nginx
systemctl is-active snap.certbot.renew.timer
echo "HTTPS restrito à VPN (${VPN_CIDR}) em https://${FRONTEND_PUBLIC_IP}; Certbot ${CERTBOT_VERSION}."
echo "Acesso ao site pela VPN: http://IP_PRIVADO_FRONTEND (tráfego protegido pelo túnel)."
echo "Renovação automática configurada pelo timer snap.certbot.renew."
