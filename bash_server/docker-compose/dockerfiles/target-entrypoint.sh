#!/usr/bin/env bash
set -Eeuo pipefail

: "${LAB_BOOTSTRAP_USER:=debian}"
: "${LAB_BOOTSTRAP_PASSWORD:?LAB_BOOTSTRAP_PASSWORD is required}"

printf '%s:%s\n' "$LAB_BOOTSTRAP_USER" "$LAB_BOOTSTRAP_PASSWORD" | chpasswd
install -d -m 0700 -o "$LAB_BOOTSTRAP_USER" -g "$LAB_BOOTSTRAP_USER" "/home/$LAB_BOOTSTRAP_USER/.ssh"

rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
ssh-keygen -A >/dev/null

exec "$@"
