#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export COMPOSE_PROFILES="${COMPOSE_PROFILES:-lab}"
bash ./scripts/wait-for-targets.sh

printf '%s\n' '== Ansible staged bootstrap on debian13-ansible =='
docker compose -f compose.yml exec -T ansible-controller \
  bash /workspace/lab/scripts/controller-bootstrap.sh
