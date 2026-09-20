#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export COMPOSE_PROFILES="${COMPOSE_PROFILES:-lab}"
bash ./scripts/up.sh

printf '%s\n' 'Integration is intentionally staged.'
printf '%s\n' 'Run ./scripts/run-ansible.sh for the Ansible bootstrap.'
printf '%s\n' 'Run ./scripts/run-bash.sh for the Bash smoke test.'
printf '%s\n' 'Full hardening is blocked until the script/module compatibility work is complete.'
