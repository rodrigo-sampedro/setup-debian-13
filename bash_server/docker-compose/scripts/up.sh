#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
	password="$(od -An -N24 -tx1 /dev/urandom | tr -d '[:space:]')"
	: "${LAB_VAULT_PASSWORD:?Set LAB_VAULT_PASSWORD before creating the lab .env file}"
	printf 'LAB_BOOTSTRAP_PASSWORD=%s\nLAB_VAULT_PASSWORD=%s\n' "$password" "$LAB_VAULT_PASSWORD" > .env
	chmod 0600 .env
elif ! grep -q '^LAB_VAULT_PASSWORD=' .env; then
	: "${LAB_VAULT_PASSWORD:?Set LAB_VAULT_PASSWORD to complete the existing lab .env file}"
	printf 'LAB_VAULT_PASSWORD=%s\n' "$LAB_VAULT_PASSWORD" >> .env
	chmod 0600 .env
fi

export COMPOSE_PROFILES="${COMPOSE_PROFILES:-lab}"

docker compose -f compose.yml build
docker compose -f compose.yml up -d

bash ./scripts/wait-for-targets.sh
printf '%s\n' "Lab is ready. Destructive setup is not run automatically."
