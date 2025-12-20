#!/usr/bin/env bash
#===============================================================================
# Script Name       : debian13_init.sh
# Description       : This is a first step to run in a new Debian 13 server.
# Author            : Rodrigo Sampedro Casis
# Creation date     : 2025-12-19
# Version           : 1.0
# How use           : ./debian13_init.sh 
#===============================================================================
# Init Base Script - Debian 13 VPS Bootstrap & Hardening
#===============================================================================
set -Eeuo pipefail
IFS=$'\n\t'


# =============================================================================
# CONFIGURATION
# =============================================================================

STATE_FILE="/var/lib/init_phase1.laststep"
# --- SSH ---
SSH_PORT=2222
SSH_ALLOWED_USERS=( "administrator" "deployer" "ropnom" )
# --- USERS ---
# Format: username:password(empty=ask)
USERS=(
  "administrator:"
  "deployer:"
  "ropnom:"
)
# --- SUDO POLICIES ---
# Format: username:rule
SUDO_RULES=(
  "administrator:ALL=(ALL) NOPASSWD:ALL"
  "ropnom:ALL=(ALL) ALL"
  "deployer:ALL=(ALL) NOPASSWD:/usr/bin/docker,/usr/bin/docker-compose"
)
# --- FIREWALL ---
FIREWALL_ALLOWED_PORTS=(
  "${SSH_PORT}/tcp"
  "80/tcp"
  "443/tcp"
)
# --- SYSCTL ---
declare -A SYSCTL_CONF=(
  [net.ipv4.ip_forward]=0
  [net.ipv4.conf.all.accept_redirects]=0
  [net.ipv4.conf.all.send_redirects]=0
  [net.ipv4.conf.all.rp_filter]=1
  [net.ipv4.tcp_syncookies]=1
  [kernel.kptr_restrict]=2
  [kernel.dmesg_restrict]=1
)
# --- SOFTWARE to install ---
MANDATORY_PACKAGES=(
  sudo git ansible vim
  curl wget gnupg ca-certificates
  ufw fail2ban auditd unattended-upgrades apt-listchanges
)
# --- ANSIBLE ---
ANSIBLE_PROJECT_REPO="git@github.com:YOURORG/vps-hardening.git"
ANSIBLE_PROJECT_DIR="/opt/vps-hardening"
# --- LOGGING ---
LOG_FILE="/var/log/init_phase1.log"


# =============================================================================
# STEPS DEFINITION (ORDER MATTERS)
# =============================================================================
STEPS=(
  check_privileges
  check_os
  show_configuration
  ask_confirmation
  configure_apt
  install_software
  create_users
  configure_sudo
  configure_ssh
  configure_firewall
  configure_sysctl
  bootstrap_ansible
)
STEP_TOTAL="${#STEPS[@]}"

# =============================================================================
# LOGGING CORE
# =============================================================================
log() {
  echo -e "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}
ok() {
  echo -e "[$(date '+%F %T')] \e[32m[ OK ]\e[0m $*" | tee -a "$LOG_FILE"
}
fail() {
  echo -e "[$(date '+%F %T')] \e[31m[FAIL]\e[0m $*" | tee -a "$LOG_FILE"
  exit 1
}
run() {
  "$@" &>>"$LOG_FILE" && ok "$*" || fail "$*"
}

# =============================================================================
# STEP STATE HANDLING
# =============================================================================
load_last_step() {
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo 0
}
save_last_step() {
  echo "$1" >"$STATE_FILE"
}

# =============================================================================
# PRE-FLIGHT & CONFIRMATION
# =============================================================================
check_privileges() {
  [[ $EUID -eq 0 ]] || fail "Must be executed as root or via sudo \n"
  ok "Superuser privileges confirmed \n"
}

check_os() {
  grep -q "Debian GNU/Linux 13" /etc/os-release \
    && ok " ** Debian 13 detected **\n" \
    || fail "X--> Unsupported OS\n"
}

join_by() {
  local sep="$1"
  shift
  local out
  printf -v out "%s${sep}" "$@"
  echo "${out%${sep}}"
}

show_configuration() {
  log "\n================ CONFIGURATION SUMMARY ================"
  log "SSH Port: ${SSH_PORT}"
  log "SSH Allowed Users: $(join_by ' ' "${SSH_ALLOWED_USERS[@]}")"
  log "Firewall Open Ports: $(join_by ' ' "${FIREWALL_ALLOWED_PORTS[@]}")"
  log "Mandatory packages: $(join_by ' ' "${MANDATORY_PACKAGES[@]}")"
  log "Users to create:"
  for u in "${USERS[@]}"; do
    IFS=":" read -r user pass <<<"$u"
    log "  - $user (password: ${pass:-INTERACTIVE})"
  done
  log "=======================================================\n"
}


ask_confirmation() {
  read -rp "Proceed with this configuration? [y/yes]:" ans
  case "$ans" in
    y|Y|yes|YES) ok "Execution confirmed\n" ;;
    *) fail "Execution aborted by user\n" ;;
  esac
  echo "\n"
}

# =============================================================================
# SYSTEM
# =============================================================================

configure_apt() {
  log "--> Configuring APT repositories\n"
  sed -i 's/^Components:.*/Components: main contrib non-free non-free-firmware/' \
    /etc/apt/sources.list.d/debian.sources || true
  log "--> Update repositories \n"
  run apt update
  log "--> Full upgrade of server\n"
  run apt full-upgrade -y
}

install_software() {
  log "--> Installing software\n"
  run apt install -y "${MANDATORY_PACKAGES[@]}"
}

# =============================================================================
# USERS & SUDO
# =============================================================================

prompt_password() {
  local user="$1"
  local pass1 pass2

  while true; do
    read -rsp "Enter password for $user: \n" pass1; echo
    read -rsp "Confirm password for $user: \n" pass2; echo

    if [[ -z "$pass1" ]]; then
      echo "Password cannot be empty\n"
      continue
    fi

    if [[ "$pass1" != "$pass2" ]]; then
      echo "Passwords do not match, try again.\n"
      continue
    fi

    break
  done

  printf '%s' "$pass1"
}

create_users() {
  log "--> Creating Users\n"
  for entry in "${USERS[@]}"; do
    IFS=":" read -r user pass <<<"$entry"

    if id "$user" &>/dev/null; then
      ok "User $user already exists"
      continue
    fi

    run useradd -m -s /bin/bash "$user"

    if [[ -z "$pass" ]]; then
      pass="$(prompt_password "$user")"
    fi

    chpasswd <<<"${user}:${pass}"
    rc=$?

    if [[ $rc -eq 0 ]]; then
    ok "Password set for $user"
    else
    fail "Failed to set password for $user"
    fi


    ok "User $user created"
  done
}


configure_sudo() {
  for rule in "${SUDO_RULES[@]}"; do
    IFS=":" read -r user policy <<<"$rule"
    echo "$user $policy" >/etc/sudoers.d/"$user"
    chmod 0440 /etc/sudoers.d/"$user"
    ok "Sudo configured for $user"
  done
}

# =============================================================================
# SSH & FIREWALL
# =============================================================================

configure_ssh() {
  log "** Hardening SSH configuration **\n"

  local cfg="/etc/ssh/sshd_config"

  # Backup defensivo
  cp "$cfg" "${cfg}.bak.$(date +%s)"

  # Port
  log "-->Changing port to ${SSH_PORT} \n"
  sed -i "s/^#\?Port .*/Port ${SSH_PORT}/" "$cfg"

  # Root login
  log "-->No allow root login\n"
  sed -i "s/^#\?PermitRootLogin .*/PermitRootLogin no/" "$cfg"

  # Password auth
  log "-->No password auth\n"
  sed -i "s/^#\?PasswordAuthentication .*/PasswordAuthentication no/" "$cfg"

  # AllowUsers (idempotente)
  # Remove previous AllowUsers
  log "-->Allowing just specific users\n"
  sed -i "/^AllowUsers /d" "$cfg"

  # Build AllowUsers line safely
  local allow_users
  allow_users="$(printf '%s ' "${SSH_ALLOWED_USERS[@]}")"
  allow_users="${allow_users% }"
  echo "AllowUsers $allow_users" >>"$cfg"


  # Debian-specific runtime dir
  if [[ ! -d /run/sshd ]]; then
    mkdir -p /run/sshd
    chmod 0755 /run/sshd
    ok "/run/sshd ensured"
  fi

  # Validar ANTES de reiniciar
  if sshd -t; then
    ok "sshd_config validation successful\n"
    systemctl restart ssh
    ok "SSH service restarted\n"
  else
    fail "Invalid sshd_config, SSH NOT restarted\n"
  fi
}


configure_firewall() {
  run ufw default deny incoming
  run ufw default allow outgoing
  for p in "${FIREWALL_ALLOWED_PORTS[@]}"; do
    run ufw allow "$p"
  done
  run ufw --force enable
}

# =============================================================================
# SYSCTL
# =============================================================================

configure_sysctl() {
  log "** Configuring Sysctl **\n"
  local f="/etc/sysctl.d/99-hardening.conf"
  : >"$f"
  for k in "${!SYSCTL_CONF[@]}"; do
    echo "$k=${SYSCTL_CONF[$k]}" >>"$f"
  done
  run sysctl --system
}

# =============================================================================
# ANSIBLE
# =============================================================================

bootstrap_ansible() {
  log "** Setup Andible project **\n"
  install -d -m 0755 "$(dirname "$ANSIBLE_PROJECT_DIR")"
  [[ -d "$ANSIBLE_PROJECT_DIR/.git" ]] \
    && ok "Ansible project already present" \
    || run git clone "$ANSIBLE_PROJECT_REPO" "$ANSIBLE_PROJECT_DIR"
}

# =============================================================================
# MAIN EXECUTION ENGINE
# =============================================================================

main() {
  local last_step current=0
  last_step="$(load_last_step)"

  log "Last completed step: $last_step"

  for fn in "${STEPS[@]}"; do
    current=$((current + 1))
    if (( current <= last_step )); then
      log "[ ${current} / ${STEP_TOTAL} ] Skipping $fn (already done)"
      continue
    fi

    log "[ ${current} / ${STEP_TOTAL} ] Executing $fn"
    "$fn"
    save_last_step "$current"
  done

  log "===== PHASE 1 COMPLETED SUCCESSFULLY ====="
}

main "$@"
