# Copilot Instructions - Debian 13 Secure Server

## Mission
Automate a secure, reproducible and recoverable Debian 13 reference server.
Both implementation paths (`ansible/` and `bash_server/`) must enforce the same security contract.
Prefer least privilege, explicit exposure, auditability, idempotency and fresh-host redeploy.

## Critical security rules (never violate)
- Default deny / least privilege / disabled by default.
- Disable root SSH login and password authentication once key access is verified.
- `debian` = bootstrap-only account. Never leave it as normal SSH path.
- `deployer` = normal operational account. Sudo must be an explicit allowlist (never unrestricted root).
- `administrator` = root-level, disabled by default, never directly reachable via SSH. Use only controlled break-glass workflow.
- Remote access only via asymmetric keys. Define enrollment, rotation and revocation.
- Firewall: default deny. Open only documented ports for the declared exposure class.
- Public, VPN-only and internal services are distinct exposure classes — never conflate them.
- Public services go behind controlled reverse-proxy + TLS (exceptions must be documented).
- Containers: no unnecessary privileges, host networking or host mounts. Never bake secrets into images.
- Never hardcode private keys, tokens, passwords or credentials.
- No undocumented manual steps in bootstrap, deploy, backup, restore or redeploy.
- Never use `curl | sh` for privileged production setup unless source integrity + pinning is explicitly controlled.

## Repository ownership
- `ansible/` → declarative IaC (roles, inventory, vars). Prefer modules over shell. Keep idempotent.
- `bash_server/` → modular Bash + compiled standalone. Change source, then regenerate `compiled/`.
- Shared behavior must be implemented in both paths when both support it.
- Never put secrets in plain text. Use Ansible Vault or approved external store.

## Ansible rules
- Prefer built-in modules and Debian-native mechanisms.
- Tasks must be idempotent (document + guard if not possible).
- Use variables for ports, users, keys, networks, paths and feature flags.
- Handlers for service restarts. Support check-mode and diff.
- Explicit privilege escalation only where required.
- Assert Debian 13 and prerequisites when needed.
- Validate: syntax, inventory, `--check --diff`, targeted tags, and re-run for idempotency.

## Bash rules
- Use `set -Eeuo pipefail` where compatible.
- Quote expansions, validate inputs, use safe temp files + cleanup traps.
- Reuse `bash_server/lib/` functions. Do not duplicate logging/config/error handling.
- Modules must be domain-focused and re-run safe (detect state first).
- Support `--help`, `--dry-run` and non-interactive mode.
- Never continue after security-critical failure. Return meaningful exit codes.
- Treat `compiled/` as generated. Verify compiler output.
- Prefer shellcheck-compatible syntax.

## Design review (before every change)
Determine:
- Owning domain and affected path (Ansible / Bash / both)
- Privilege, exposure and secret impact
- Backup / restore / redeploy impact
- Validation commands and acceptance criteria

Reject or escalate anything that requires:
- Permanent broad sudo
- Public exposure without TLS + logging policy
- Insecure secret storage
- Hidden manual steps
- Recovery path that cannot meet project objectives

## Trust zones (preserve separation)
host administration · bootstrap-only · deployer · controlled administrator · public ingress · VPN-only · internal container networks · isolated sensitive networks · backup storage

Every service must declare: owner, image + pin, networks, volumes, secrets, ports, restart policy, logs, healthchecks, backup class and restore method.

## Operational outcomes (must preserve)
- Bootstrap to secure admin-ready host ≤ 30 min
- Full fresh-host redeploy ≤ 60 min
- Administrator activation/deactivation ≤ 10 min (audited)
- Scheduled backup restore validation for critical services
- Timely critical security updates
- Repeatable validation of SSH, firewall, fail2ban, Docker, exposure, VPN, backup and redeploy

## Validation minimum
- Ansible: syntax, inventory, `--check --diff`, tags, re-run for idempotency
- Bash: `bash -n`, ShellCheck, `--dry-run`, clean + re-run tests, compiler verification
- Security: SSH config, authorized_keys, sudo rules, listening ports, firewall default, fail2ban, Docker privileges/networks
- Recovery: backup integrity + restore + fresh redeploy evidence

A change is complete only when owned behavior is implemented, security/recovery impact is explicit, validation passes, and documentation reflects the supported path.