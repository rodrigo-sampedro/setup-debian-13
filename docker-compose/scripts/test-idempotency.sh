#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export COMPOSE_PROFILES="${COMPOSE_PROFILES:-lab}"
bash ./scripts/wait-for-targets.sh

printf '%s\n' '== Ansible idempotency gate =='
bash ./scripts/run-ansible.sh
printf '%s\n' 'Run the command again after the first successful bootstrap and compare the changed-task count.'
printf '%s\n' 'Automatic zero-change enforcement will be enabled with the full role test suite.'
