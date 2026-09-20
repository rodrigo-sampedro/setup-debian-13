#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p /root/.ssh /workspace/lab/results
chmod 0700 /root/.ssh

: "${LAB_BOOTSTRAP_PASSWORD:?LAB_BOOTSTRAP_PASSWORD is required}"
: "${LAB_VAULT_PASSWORD:?LAB_VAULT_PASSWORD is required}"

cat > /workspace/lab/ansible.cfg <<'EOF'
[defaults]
inventory = /workspace/lab/runtime-hosts.yaml
roles_path = /workspace/ansible/roles
host_key_checking = False
remote_user = debian
private_key_file = /root/.ssh/id_ed25519
remote_tmp = /tmp/.ansible-${USER}/tmp
timeout = 30
log_path = /workspace/lab/results/ansible.log
stdout_callback = yaml
deprecation_warnings = False
retry_files_enabled = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=60s
EOF

printf '%s\n' "$LAB_VAULT_PASSWORD" > /workspace/lab/results/vault-password
chmod 0600 /workspace/lab/results/vault-password
cat > /workspace/lab/runtime-hosts.yaml <<EOF
all:
  children:
    vps_servers:
      hosts:
        debian13-ansible:
          ansible_host: debian13-ansible
          ansible_port: 22
          ansible_user: debian
          ansible_password: "${LAB_BOOTSTRAP_PASSWORD}"
          ansible_become_password: "${LAB_BOOTSTRAP_PASSWORD}"
          ansible_python_interpreter: /usr/bin/python3
          ansible_ssh_common_args: "-o StrictHostKeyChecking=no"
          exposure_class: internal
EOF
chmod 0600 /workspace/lab/runtime-hosts.yaml

if [[ ! -f /root/.ssh/id_ed25519 ]]; then
  ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/id_ed25519 -C lab-controller
fi

if [[ ! -f /root/.ssh/known_hosts ]]; then
  touch /root/.ssh/known_hosts
  chmod 0600 /root/.ssh/known_hosts
fi

exec "$@"
