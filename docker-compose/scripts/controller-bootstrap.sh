#!/usr/bin/env bash
set -Eeuo pipefail

key="$(cat /root/.ssh/id_ed25519.pub)"
extra_vars=/tmp/lab-extra-vars.json

python3 - "$key" > "$extra_vars" <<'PY'
import json
import sys

print(json.dumps({
    "vault_deployer_authorized_keys": [sys.argv[1]],
    "ssh_hardening_enabled": False,
    "run_validation": False,
}))
PY

ansible-playbook \
  --extra-vars "@$extra_vars" \
  --vault-password-file /workspace/lab/results/vault-password \
  --limit debian13-ansible \
  --tags bootstrap,users \
  -i /workspace/lab/runtime-hosts.yaml \
  /workspace/ansible/site.yml

printf '%s\n' '== Verify deployer key authentication =='
ssh -o StrictHostKeyChecking=no -o BatchMode=yes \
  -o UserKnownHostsFile=/dev/null \
  -i /root/.ssh/id_ed25519 deployer@debian13-ansible id -u
