#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"
cd "$ROOT_DIR"

printf '%s\n' '== Compose config =='
docker compose -f compose.yml config --quiet

printf '%s\n' '== Ansible syntax =='
docker compose run --rm --no-deps ansible-controller \
  ansible-playbook --syntax-check --vault-password-file /workspace/lab/results/vault-password /workspace/ansible/site.yml

docker compose run --rm --no-deps ansible-controller \
  ansible-inventory --graph

printf '%s\n' '== Bash syntax =='
docker compose run --rm --no-deps ansible-controller bash -lc \
  'find /workspace/bash_server -type f -name "*.sh" -print0 | xargs -0 -n1 bash -n'

if command -v shellcheck >/dev/null 2>&1; then
  docker compose run --rm --no-deps ansible-controller bash -lc \
   'shellcheck -S error /workspace/bash_server/debian_setup_modular.sh /workspace/bash_server/compile_script.sh /workspace/bash_server/lib/*.sh /workspace/bash_server/modules/*.sh'
fi

printf '%s\n' "Static checks passed for $PROJECT_ROOT"
