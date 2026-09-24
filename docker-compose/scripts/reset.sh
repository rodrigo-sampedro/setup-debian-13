#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# This project name is fixed so reset cannot touch unrelated Compose projects.
docker compose -p debian13-setup-lab -f compose.yml down --volumes --remove-orphans
