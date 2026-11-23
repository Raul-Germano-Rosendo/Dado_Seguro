#!/usr/bin/env bash
# Configura um usuário SFTP restrito a uma pasta de recebimento (sem shell).
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute com sudo: sudo bash configure-sftp.sh /caminho/chave-publica.pub" >&2
  exit 1
fi

PUBLIC_KEY_FILE="${1:-}"
SFTP_USER="dado-sftp"
SFTP_GROUP="dado-sftp-only"
CHROOT="/srv/sftp/${SFTP_USER}"

if [[ ! -s "${PUBLIC_KEY_FILE}" ]]; then
  echo "Informe um arquivo de chave pública SSH existente." >&2
  exit 1
fi
if ! grep -Eq '^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp[0-9]+) ' "${PUBLIC_KEY_FILE}"; then
  echo "O arquivo informado não parece conter uma chave pública OpenSSH válida." >&2
  exit 1
fi

getent group "${SFTP_GROUP}" >/dev/null || groupadd --system "${SFTP_GROUP}"
if ! id "${SFTP_USER}" >/dev/null 2>&1; then
  useradd --no-create-home --home-dir /upload --shell /usr/sbin/nologin \
    --gid "${SFTP_GROUP}" "${SFTP_USER}"
fi
usermod --shell /usr/sbin/nologin --home /upload --gid "${SFTP_GROUP}" "${SFTP_USER}"
# Leave a random, unknown password hash so PAM does not reject the account;
# this Match block still requires public-key authentication only.
printf '%s:%s\n' "${SFTP_USER}" "$(openssl rand -hex 32)" | chpasswd

install -d -o root -g root -m 0755 /srv/sftp
install -d -o root -g root -m 0755 "${CHROOT}"
install -d -o "${SFTP_USER}" -g "${SFTP_GROUP}" -m 0750 "${CHROOT}/upload"
install -d -o root -g root -m 0755 /etc/ssh/authorized_keys
# Public keys are not secret; world-readable mode lets the unprivileged sshd
# session read this absolute AuthorizedKeysFile on Ubuntu 26.04.
install -o root -g root -m 0644 "${PUBLIC_KEY_FILE}" \
  "/etc/ssh/authorized_keys/${SFTP_USER}"

CONFIG_MARKER="# BEGIN Dado Seguro SFTP"
if ! grep -Fq "${CONFIG_MARKER}" /etc/ssh/sshd_config; then
  cat >> /etc/ssh/sshd_config <<'SSHD_CONFIG'

# BEGIN Dado Seguro SFTP
Match Group dado-sftp-only
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp -d /upload -u 027
    AuthorizedKeysFile /etc/ssh/authorized_keys/%u
    AuthenticationMethods publickey
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PermitTTY no
    AllowTcpForwarding no
    AllowAgentForwarding no
    X11Forwarding no
    PermitTunnel no
# END Dado Seguro SFTP
SSHD_CONFIG
fi

sshd -t
systemctl reload ssh
sshd -T -C "user=${SFTP_USER},host=localhost,addr=127.0.0.1" | \
  grep -E '^(chrootdirectory|forcecommand|authorizedkeysfile|authenticationmethods|passwordauthentication|allowtcpforwarding|permittty) '
echo "SFTP pronto: usuário ${SFTP_USER}, diretório gravável /upload, sem shell e sem senha."
