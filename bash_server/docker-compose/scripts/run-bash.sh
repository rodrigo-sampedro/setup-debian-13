#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export COMPOSE_PROFILES="${COMPOSE_PROFILES:-lab}"
bash ./scripts/wait-for-targets.sh

printf '%s\n' '== Bash source inventory =='
docker compose -f compose.yml exec -T debian13-bash \
  bash -lc 'find /workspace/bash_server -maxdepth 2 -type f -name "*.sh" -print | sort'

printf '%s\n' '== Bash help smoke test =='
docker compose -f compose.yml exec -T debian13-bash \
  bash /workspace/bash_server/compiled/setup_debian13.sh --help

printf '%s\n' 'Bash smoke test completed. Full setup remains explicit and destructive.'
