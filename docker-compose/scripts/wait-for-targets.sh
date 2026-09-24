#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for service in debian13-ansible debian13-bash; do
  for attempt in $(seq 1 60); do
    if docker compose -f compose.yml ps --status running "$service" | grep -q "$service"; then
      if docker compose -f compose.yml exec -T "$service" ss -lnt | grep -q ':22 '; then
        printf '%s\n' "$service is ready"
        break
      fi
    fi
    if [[ "$attempt" == 60 ]]; then
      docker compose -f compose.yml logs "$service"
      printf '%s\n' "Timed out waiting for $service" >&2
      exit 1
    fi
    sleep 2
  done
done
