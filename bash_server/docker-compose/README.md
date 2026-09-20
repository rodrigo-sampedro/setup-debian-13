# Debian 13 setup lab

This Compose project is a disposable integration lab for the Ansible and Bash implementations. It is not a production server and must not be used with real credentials.

## Services

- `ansible-controller`: Ubuntu 24.04 with Ansible, SSH client, sshpass and ShellCheck.
- `debian13-ansible`: Debian 13 target for staged Ansible bootstrap.
- `debian13-bash`: independent Debian 13 target with the Bash project mounted read-only.

The controller's generated Ansible configuration targets `debian13-ansible` by
default. The Bash smoke and integration commands target `debian13-bash` by
default. The production inventory under `ansible/inventory/` is not changed by
this lab.

The targets run privileged with systemd and Docker-in-Docker so service-level tests can run. The host Docker socket is deliberately not mounted. Firewall, kernel, swap and auditd results inside a container are not equivalent to a real Debian host.

## Start the lab

From this directory in WSL or a Linux terminal:

```bash
./scripts/up.sh
```

`up.sh` builds the images, starts the three services and waits for both target SSH daemons. It does not execute hardening.

## Static validation

```bash
./scripts/test-static.sh
```

## Staged Ansible bootstrap

```bash
./scripts/run-ansible.sh
```

The controller generates a temporary Ed25519 key in the named `lab-ssh` volume. The test-only Vault fixture is replaced at runtime with that public key through Ansible extra vars. The target is first reached with the lab password; the script then verifies key authentication as `deployer`.

The current command intentionally runs only `bootstrap,users`. SSH hardening and final service validation remain separate gates until the target role dependencies and key verification workflow are complete.

## Bash smoke test

```bash
./scripts/run-bash.sh
```

This lists the mounted source and runs the compiled script help command. Full Bash setup is intentionally not automatic because the current source/compiler module names and container-only capabilities still require remediation.

## Reset

```bash
./scripts/reset.sh
```

This removes only the fixed Compose project and its volumes. It is the clean redeploy path.

## Lab password

`up.sh` generates a random lab-only password in the ignored `.env` file. Override it without editing tracked files:

```bash
export LAB_BOOTSTRAP_PASSWORD='another-lab-only-value'
./scripts/up.sh
```

Do not commit `.env` or use this mechanism for a real server; production bootstrap credentials belong outside Git and should be supplied through Ansible password prompting or a secret manager.

The test Vault fixture is encrypted and mounted as `ansible/vars/vault.yml`.
Set `LAB_VAULT_PASSWORD` in your local environment before the first `up.sh`
run so the controller can run syntax and bootstrap tests without prompting.
This password is for the disposable test fixture only and must not be committed.

## Known limits

A real Debian 13 VM or Incus instance is still required to validate host-level firewall behavior, kernel/sysctl changes, swap, auditd, reboot recovery and Docker isolation. These checks must be reported as `UNSUPPORTED`, never as passing container tests.
