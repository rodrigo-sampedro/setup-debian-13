#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export COMPOSE_PROFILES="${COMPOSE_PROFILES:-lab}"
bash ./scripts/wait-for-targets.sh

printf '%s\n' '== Target process checks =='
for service in debian13-ansible debian13-bash; do
  docker compose -f compose.yml exec -T "$service" systemctl is-active ssh
  docker compose -f compose.yml exec -T "$service" ss -lnt | grep ':22 '
done

printf '%s\n' 'UNSUPPORTED in container lab: host firewall, kernel sysctl, swap, auditd isolation.'
printf '%s\n' 'Supported target process checks passed.'
