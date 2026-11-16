#!/bin/bash
# Modelo didático de User Data para Amazon Linux 2023.
# Revise AMI e comandos no ambiente de destino antes de usar.
set -euo pipefail

dnf update -y
dnf install -y nginx curl

# O serviço não é habilitado automaticamente. Após revisar firewall e web:
# systemctl enable --now nginx
