#!/usr/bin/env bash
#===============================================================================
# Script Name       : setup_debian13.sh
# Description       : Debian 13 Setup VPS Users, ssh, fail2ban ufw and docker
# Author            : Rodrigo Sampedro Casis
# Creation date     : 2025-12-26
# Version           : 1.1
# Usage  demo       : ./setup_debian13.sh [--no-menu] [--dry-run]
# Usage             : ./setup_debian13.sh
#===============================================================================
set -Eeuo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION
# =============================================================================

STATE_FILE="/var/lib/init_phase1.laststep"
DRY_RUN=false

# --- SSH ---
SSH_PORT=2222
SSH_ALLOWED_USERS=( "administrator" "deployer" "tuUser" )
SSH_MAX_AUTH_TRIES=3
SSH_MAX_SESSIONS=2
SSH_CLIENT_ALIVE_INTERVAL=300
SSH_CLIENT_ALIVE_COUNT_MAX=2

# --- USERS ---
# Format: username:password(empty=ask):sshkey_url_or_path
USERS=(
  "administrator:passStrong:"
  "deployer:pass&:"
  "tuUser:pass:"
)

# --- SUDO POLICIES ---
# Format: username:rule
SUDO_RULES=(
  "administrator:ALL=(ALL) NOPASSWD:ALL"
  "tuUser:ALL=(ALL) ALL"
  "deployer:ALL=(ALL) NOPASSWD:/usr/local/bin/docker-deploy,/usr/local/bin/docker-manage"
)

# --- FIREWALL ---
FIREWALL_ALLOWED_PORTS=(
  "${SSH_PORT}/tcp"
  "80/tcp"
  "443/tcp"
)


# --- GEO-BLOCKING ---
BLOCKED_COUNTRIES=("CN" "RU" "KP" "IR" "PK" "BY")

# --- SYSCTL ---
declare -A SYSCTL_CONF=(
  [net.ipv4.ip_forward]=1
  [net.ipv4.conf.all.accept_redirects]=0
  [net.ipv4.conf.all.send_redirects]=0
  [net.ipv4.conf.all.rp_filter]=1
  [net.ipv4.conf.all.log_martians]=1
  [net.ipv4.tcp_syncookies]=1
  [net.ipv4.tcp_timestamps]=0
  [net.ipv6.conf.all.disable_ipv6]=1
  [net.ipv6.conf.default.disable_ipv6]=1
  [kernel.kptr_restrict]=2
  [kernel.dmesg_restrict]=1
  [kernel.yama.ptrace_scope]=2
  [kernel.unprivileged_userns_clone]=0
  [fs.suid_dumpable]=0
  [vm.swappiness]=10
)

# --- SOFTWARE ---
MANDATORY_PACKAGES=(
  sudo git vim nano htop ncdu rsync
  curl wget gnupg ca-certificates lsb-release
  ufw fail2ban auditd unattended-upgrades apt-listchanges
  net-tools dnsutils clamav clamav-daemon rkhunter chkrootkit
)

# --- DOCKER ---
DOCKER_PACKAGES=(
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
)

# --- DOCKER DEPLOY GROUP ---
DOCKER_DEPLOY_GROUP="docker_deploy"
DOCKER_DEPLOY_BASE_DIR="/opt/docker-projects"

# --- TIMEZONE ---
TIMEZONE="Europe/Madrid"

# --- SWAP ---
SWAP_SIZE="2G"
SWAP_FILE="/swapfile"

# --- HARDENING SCRIPT ---
FORTRESS_SCRIPT_URL="https://raw.githubusercontent.com/captainzero93/security_harden_linux/main/fortress_improved.sh"
FORTRESS_SCRIPT="/root/fortress_improved.sh"

# --- SSH BANNER ---
SSH_BANNER_FILE="/etc/ssh/banner"

# --- LOGGING ---
LOG_FILE="/var/log/init_phase1.log"
LOG_LEVEL=1  # 0=ERROR, 1=INFO, 2=DEBUG

# =============================================================================
# STEPS DEFINITION
# =============================================================================
STEPS=(
  check_privileges
  check_os
  show_configuration
  ask_confirmation
  backup_configs
  configure_timezone
  configure_locale
  configure_apt
  install_software
  configure_swap
  create_docker_deploy_group
  create_users
  setup_ssh_keys
  configure_sudo
  create_docker_helper_scripts
  setup_docker_aliases
  install_docker
  configure_docker_daemon
  setup_docker_projects_dir
  configure_ssh_banner
  configure_ssh
  configure_firewall
  configure_fail2ban
  setup_geoip_blocking
  configure_sysctl
  configure_auditd
  configure_unattended_upgrades
  configure_logrotate
  install_endlessh
  configure_clamav
  configure_rkhunter
  download_fortress_script
  generate_documentation
  final_security_check
)
STEP_TOTAL="${#STEPS[@]}"

# =============================================================================
# LOGGING CORE
# =============================================================================
log() {
  [[ $LOG_LEVEL -ge 1 ]] && echo -e "[$(date '+%F %T')] [INFO] $*" | tee -a "$LOG_FILE"
}

debug() {
  [[ $LOG_LEVEL -ge 2 ]] && echo -e "[$(date '+%F %T')] [DEBUG] $*" | tee -a "$LOG_FILE"
}

ok() {
  echo -e "[$(date '+%F %T')] \e[32m[ OK ]\e[0m $*" | tee -a "$LOG_FILE"
}

warn() {
  echo -e "[$(date '+%F %T')] \e[33m[WARN]\e[0m $*" | tee -a "$LOG_FILE"
}

fail() {
  echo -e "[$(date '+%F %T')] \e[31m[FAIL]\e[0m $*" | tee -a "$LOG_FILE"
  exit 1
}

run() {
  if $DRY_RUN; then
    log "[DRY-RUN] Would execute: $*"
    return 0
  fi
  
  debug "Executing: $*"
  if "$@" &>>"$LOG_FILE"; then
    ok "✓ $*"
    return 0
  else
    fail "✗ $*"
    return 1
  fi
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
load_last_step() {
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo 0
}

save_last_step() {
  if ! $DRY_RUN; then
    echo "$1" >"$STATE_FILE"
  fi
}

clear_last_step() {
  if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
    ok "Progress file cleared: $STATE_FILE"
  else
    log "No progress file to clear"
  fi
}

join_by() {
  local sep="$1"
  shift
  local out
  printf -v out "%s${sep}" "$@"
  echo "${out%${sep}}"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
check_privileges() {
  [[ $EUID -eq 0 ]] || fail "Must be executed as root or via sudo"
  ok "Superuser privileges confirmed"
}

check_os() {
  if grep -q "Debian GNU/Linux 13" /etc/os-release; then
    ok "Debian 13 detected"
  else
    fail "Unsupported OS - This script requires Debian 13"
  fi
}

show_configuration() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║           CONFIGURATION SUMMARY                            ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  log ""
  log "SSH Configuration:"
  log "  Port: ${SSH_PORT}"
  log "  Allowed Users: $(join_by ', ' "${SSH_ALLOWED_USERS[@]}")"
  log "  Max Auth Tries: ${SSH_MAX_AUTH_TRIES}"
  log "  SSH Banner: Enabled"
  log ""
  log "Security:"
  log "  Geo-blocking: $(join_by ', ' "${BLOCKED_COUNTRIES[@]}")"
  log "  SSH Tarpit (endlessh): Port 22"
  log "  ClamAV: Enabled with periodic scans"
  log "  Rootkit detection: rkhunter + chkrootkit"
  log ""
  log "Firewall Ports:"
  log "  $(join_by ', ' "${FIREWALL_ALLOWED_PORTS[@]}")"
  log ""
  log "System:"
  log "  Timezone: ${TIMEZONE}"
  log "  Swap Size: ${SWAP_SIZE}"
  log ""
  log "Docker Deploy:"
  log "  Group: ${DOCKER_DEPLOY_GROUP}"
  log "  Projects Dir: ${DOCKER_DEPLOY_BASE_DIR}"
  log ""
  log "Users to create:"
  for u in "${USERS[@]}"; do
    IFS=":" read -r user pass sshkey <<<"$u"
    log "  - $user (password: ${pass:-INTERACTIVE}, ssh key: ${sshkey:-NONE})"
  done
  log ""
  log "Docker: Will be installed from official repository"
  log "Additional Hardening: fortress_improved.sh will be downloaded"
  log ""
  log "═══════════════════════════════════════════════════════════"
  log ""
}

ask_confirmation() {
  if $DRY_RUN; then
    ok "DRY-RUN mode: skipping confirmation"
    return 0
  fi
  
  read -rp "Proceed with this configuration? [y/yes]: " ans
  case "$ans" in
    y|Y|yes|YES) ok "Execution confirmed" ;;
    *) fail "Execution aborted by user" ;;
  esac
}

# =============================================================================
# BACKUP
# =============================================================================
backup_configs() {
  log "Creating backup of critical configuration files"
  local backup_dir="/root/config_backup_$(date +%Y%m%d_%H%M%S)"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would create backup in: $backup_dir"
    return 0
  fi
  
  mkdir -p "$backup_dir"
  
  local files_to_backup=(
    "/etc/ssh/sshd_config"
    "/etc/apt/sources.list.d/debian.sources"
    "/etc/sysctl.conf"
    "/etc/fstab"
  )
  
  for file in "${files_to_backup[@]}"; do
    if [[ -f "$file" ]]; then
      cp -a "$file" "$backup_dir/" 2>/dev/null || true
      debug "Backed up: $file"
    fi
  done
  
  ok "Configuration backup created in: $backup_dir"
}

# =============================================================================
# SYSTEM CONFIGURATION
# =============================================================================
configure_timezone() {
  log "Configuring timezone to ${TIMEZONE}"
  run timedatectl set-timezone "$TIMEZONE"
}

configure_locale() {
  log "Configuring locale"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure locales"
    return 0
  fi
  
  if ! grep -q "^en_US.UTF-8" /etc/locale.gen; then
    sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
  fi
  
  if ! grep -q "^es_ES.UTF-8" /etc/locale.gen; then
    sed -i 's/^# es_ES.UTF-8/es_ES.UTF-8/' /etc/locale.gen
  fi
  
  locale-gen &>>"$LOG_FILE"
  ok "Locales configured"
}

configure_apt() {
  log "Configuring APT repositories"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would update APT sources"
    return 0
  fi
  
  sed -i 's/^Components:.*/Components: main contrib non-free non-free-firmware/' \
    /etc/apt/sources.list.d/debian.sources || true
  
  run apt update
  log "Performing full system upgrade (this may take a while)"
  run apt full-upgrade -y
  run apt autoremove -y
  run apt autoclean
}

install_software() {
  log "Installing mandatory packages"
  run apt install -y "${MANDATORY_PACKAGES[@]}"
}

configure_swap() {
  log "Configuring swap space"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would create ${SWAP_SIZE} swap at ${SWAP_FILE}"
    return 0
  fi
  
  if swapon --show | grep -q "$SWAP_FILE"; then
    ok "Swap already configured"
    return 0
  fi
  
  if [[ -f "$SWAP_FILE" ]]; then
    warn "Swap file exists but not active, removing old swap"
    swapoff "$SWAP_FILE" 2>/dev/null || true
    rm -f "$SWAP_FILE"
  fi
  
  log "Creating ${SWAP_SIZE} swap file"
  fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=2048
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE" &>>"$LOG_FILE"
  swapon "$SWAP_FILE"
  
  if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  fi
  
  ok "Swap configured and enabled"
}

# =============================================================================
# DOCKER DEPLOY GROUP
# =============================================================================
create_docker_deploy_group() {
  log "Creating docker_deploy group for shared Docker projects"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would create group: ${DOCKER_DEPLOY_GROUP}"
    return 0
  fi
  
  if getent group "${DOCKER_DEPLOY_GROUP}" >/dev/null; then
    ok "Group ${DOCKER_DEPLOY_GROUP} already exists"
  else
    groupadd "${DOCKER_DEPLOY_GROUP}"
    ok "Group ${DOCKER_DEPLOY_GROUP} created"
  fi
}

# =============================================================================
# USER MANAGEMENT
# =============================================================================
prompt_password() {
  local user="$1"
  local pass1 pass2

  exec < /dev/tty

  while true; do
    echo ""
    echo "Enter password for $user:"
    read -rs pass1
    echo ""
    echo "Confirm password for $user:"
    read -rs pass2
    echo ""

    if [[ -z "$pass1" ]]; then
      echo "Password cannot be empty"
      continue
    fi

    if [[ "$pass1" != "$pass2" ]]; then
      echo "Passwords do not match, try again"
      continue
    fi

    break
  done

  printf '%s' "$pass1"
}

create_users() {
  log "Creating system users"
  
  for entry in "${USERS[@]}"; do
    IFS=":" read -r user pass sshkey <<<"$entry"

    if id "$user" &>/dev/null; then
      ok "User $user already exists"
      
      if ! groups "$user" | grep -q "${DOCKER_DEPLOY_GROUP}"; then
        if ! $DRY_RUN; then
          usermod -aG "${DOCKER_DEPLOY_GROUP}" "$user"
          ok "Added $user to ${DOCKER_DEPLOY_GROUP} group"
        else
          log "[DRY-RUN] Would add $user to ${DOCKER_DEPLOY_GROUP} group"
        fi
      fi
      continue
    fi

    if $DRY_RUN; then
      log "[DRY-RUN] Would create user: $user"
      continue
    fi

    if useradd -m -s /bin/bash -G "${DOCKER_DEPLOY_GROUP}" "$user" &>>"$LOG_FILE"; then
      ok "User $user created"
    else
      fail "Failed to create user $user"
    fi

    if [[ -z "$pass" ]]; then
      pass="$(prompt_password "$user")"
    fi

    if printf '%s:%s\n' "$user" "$pass" | chpasswd 2>>"$LOG_FILE"; then
      ok "Password set for $user"
    else
      warn "Failed to set password for $user - check log file"
    fi

    ok "User $user setup completed (member of ${DOCKER_DEPLOY_GROUP})"
  done
}

setup_ssh_keys() {
  log "Setting up SSH keys for users"
  
  for entry in "${USERS[@]}"; do
    IFS=":" read -r user pass sshkey <<<"$entry"
    
    [[ -z "$sshkey" ]] && continue
    
    if ! id "$user" &>/dev/null; then
      warn "User $user doesn't exist, skipping SSH key setup"
      continue
    fi
    
    if $DRY_RUN; then
      log "[DRY-RUN] Would setup SSH key for $user from: $sshkey"
      continue
    fi
    
    local user_home
    user_home=$(eval echo "~$user")
    local ssh_dir="$user_home/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"
    
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    if [[ "$sshkey" =~ ^https?:// ]]; then
      log "Downloading SSH key from URL for $user"
      curl -fsSL "$sshkey" >> "$auth_keys" 2>>"$LOG_FILE" || warn "Failed to download SSH key for $user"
    elif [[ -f "$sshkey" ]]; then
      log "Copying SSH key from file for $user"
      cat "$sshkey" >> "$auth_keys"
    else
      warn "SSH key not found: $sshkey"
      continue
    fi
    
    chmod 600 "$auth_keys"
    chown -R "$user:$user" "$ssh_dir"
    
    ok "SSH key configured for $user"
  done
}

configure_sudo() {
  log "Configuring sudo policies"
  
  for rule in "${SUDO_RULES[@]}"; do
    IFS=":" read -r user policy <<<"$rule"
    
    local sudoers_file="/etc/sudoers.d/$user"
    
    if $DRY_RUN; then
      log "[DRY-RUN] Would configure sudo for $user: $policy"
      continue
    fi
    
    if [[ -f "$sudoers_file" ]]; then
      if grep -Fxq "$user $policy" "$sudoers_file"; then
        ok "Sudo already configured for $user (unchanged)"
        continue
      else
        log "Updating sudo policy for $user"
      fi
    fi
    
    echo "$user $policy" > "$sudoers_file"
    chmod 0440 "$sudoers_file"
    ok "Sudo configured for $user"
  done
}

# =============================================================================
# DOCKER HELPER SCRIPTS
# =============================================================================
create_docker_helper_scripts() {
  log "Creating Docker helper scripts"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would create Docker helper scripts"
    return 0
  fi
  
  cat > /usr/local/bin/docker-deploy << 'EOF'
#!/bin/bash
# Safe Docker deployment script
set -e

case "$1" in
  start)
    shift
    docker compose -f "$@" up -d
    ;;
  stop)
    shift
    docker compose -f "$@" down
    ;;
  restart)
    shift
    docker compose -f "$@" restart
    ;;
  logs)
    shift
    docker compose -f "$@" logs -f
    ;;
  pull)
    shift
    docker compose -f "$@" pull
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|logs|pull} <compose-file>"
    exit 1
    ;;
esac
EOF

  cat > /usr/local/bin/docker-manage << 'EOF'
#!/bin/bash
# Safe Docker management script
set -e

case "$1" in
  ps)
    shift
    docker ps "$@"
    ;;
  images)
    docker images
    ;;
  prune)
    docker system prune -f
    ;;
  stats)
    docker stats --no-stream
    ;;
  logs)
    shift
    docker logs "$@"
    ;;
  *)
    echo "Usage: $0 {ps|images|prune|stats|logs}"
    exit 1
    ;;
esac
EOF

  chmod 755 /usr/local/bin/docker-deploy
  chmod 755 /usr/local/bin/docker-manage
  
  ok "Docker helper scripts created in /usr/local/bin/"
}

setup_docker_aliases() {
  log "Setting up Docker command aliases for users"
  
  for entry in "${USERS[@]}"; do
    IFS=":" read -r user pass sshkey <<<"$entry"
    
    if ! id "$user" &>/dev/null; then
      warn "User $user doesn't exist, skipping alias setup"
      continue
    fi
    
    if $DRY_RUN; then
      log "[DRY-RUN] Would setup aliases for $user"
      continue
    fi
    
    local user_home
    user_home=$(eval echo "~$user")
    local bashrc="$user_home/.bashrc"
    
    if grep -q "alias dp=" "$bashrc" 2>/dev/null; then
      ok "Docker aliases already configured for $user"
      continue
    fi
    
    cat >> "$bashrc" << 'EOF'

# Docker helper aliases
alias dp='docker-deploy'
alias dm='docker-manage'

# Show last login
if [ -f ~/.last_login ]; then
    echo "Last login: $(cat ~/.last_login)"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S from '$(echo $SSH_CONNECTION | awk '{print $1}'))" > ~/.last_login
EOF
    
    chown "$user:$user" "$bashrc"
    ok "Docker aliases configured for $user (dp, dm)"
  done
}

# =============================================================================
# DOCKER INSTALLATION
# =============================================================================
install_docker() {
  log "Installing Docker from official repository"
  
  if command_exists docker; then
    ok "Docker already installed"
    return 0
  fi
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would install Docker"
    return 0
  fi
  
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  run apt update
  run apt install -y "${DOCKER_PACKAGES[@]}"
  
  systemctl start docker
  systemctl enable docker
  
  ok "Docker installed and enabled"
}

configure_docker_daemon() {
  log "Configuring Docker daemon for security"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure Docker daemon"
    return 0
  fi
  
  mkdir -p /etc/docker
  
  cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF

  systemctl restart docker
  ok "Docker daemon configured"
}

setup_docker_projects_dir() {
  log "Setting up Docker projects directory"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would create ${DOCKER_DEPLOY_BASE_DIR}"
    return 0
  fi
  
  if [[ ! -d "$DOCKER_DEPLOY_BASE_DIR" ]]; then
    mkdir -p "$DOCKER_DEPLOY_BASE_DIR"
  fi
  
  chown root:"${DOCKER_DEPLOY_GROUP}" "$DOCKER_DEPLOY_BASE_DIR"
  chmod 2775 "$DOCKER_DEPLOY_BASE_DIR"
  
  mkdir -p "$DOCKER_DEPLOY_BASE_DIR"/{.env,volumes}
  chown -R root:"${DOCKER_DEPLOY_GROUP}" "$DOCKER_DEPLOY_BASE_DIR"/{.env,volumes}
  chmod -R 2775 "$DOCKER_DEPLOY_BASE_DIR"/{.env,volumes}
  
  cat > "$DOCKER_DEPLOY_BASE_DIR/README.md" << EOF
# Docker Projects Directory

This directory is shared among users in the '${DOCKER_DEPLOY_GROUP}' group.

## Structure:
- \`.env/\` - Environment files for docker-compose
- \`volumes/\` - Docker volumes data
- Each project should have its own subdirectory

## Usage:
- Use 'dp' (docker-deploy) to manage compose files
- Use 'dm' (docker-manage) for container operations

## Examples:
\`\`\`bash
# Start a project
dp start /path/to/docker-compose.yml

# Check running containers
dm ps

# View logs
dm logs container_name
\`\`\`
EOF
  
  chown root:"${DOCKER_DEPLOY_GROUP}" "$DOCKER_DEPLOY_BASE_DIR/README.md"
  chmod 664 "$DOCKER_DEPLOY_BASE_DIR/README.md"
  
  ok "Docker projects directory configured at ${DOCKER_DEPLOY_BASE_DIR}"
}

# =============================================================================
# SSH BANNER
# =============================================================================
configure_ssh_banner() {
  log "Configuring SSH login banner"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure SSH banner"
    return 0
  fi
  
  cat > "$SSH_BANNER_FILE" << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                    AUTHORIZED ACCESS ONLY                      ║
╚═══════════════════════════════════════════════════════════════╝

WARNING: This system is for authorized users only. 

All activities on this system are monitored and recorded. Unauthorized 
access attempts will be prosecuted to the fullest extent of the law.

By continuing, you acknowledge that:
- You have explicit authorization to access this system
- Your actions will be logged and may be audited
- Unauthorized access is a criminal offense

If you are not an authorized user, disconnect immediately.

═══════════════════════════════════════════════════════════════════

EOF
  
  chmod 644 "$SSH_BANNER_FILE"
  ok "SSH banner created at $SSH_BANNER_FILE"
}

# =============================================================================
# SSH HARDENING
# =============================================================================
set_or_add() {
  local key="$1"
  local value="$2"
  local file="$3"

  if grep -Eq "^#?\s*${key}\b" "$file"; then
    sed -i "s|^#\?\s*${key}.*|${key} ${value}|" "$file"
  else
    echo "${key} ${value}" >> "$file"
  fi
}


configure_ssh() {
  log "Hardening SSH configuration"

  local cfg="/etc/ssh/sshd_config"

  if $DRY_RUN; then
    log "[DRY-RUN] Would harden SSH configuration"
    return 0
  fi

  cp "$cfg" "${cfg}.bak.$(date +%s)"

  set_or_add "Port" "${SSH_PORT}" "$cfg"
  set_or_add "PermitRootLogin" "no" "$cfg"
  set_or_add "PasswordAuthentication" "no" "$cfg"
  set_or_add "PubkeyAuthentication" "yes" "$cfg"
  set_or_add "PermitEmptyPasswords" "no" "$cfg"
  set_or_add "MaxAuthTries" "${SSH_MAX_AUTH_TRIES}" "$cfg"
  set_or_add "MaxSessions" "${SSH_MAX_SESSIONS}" "$cfg"
  set_or_add "ClientAliveInterval" "${SSH_CLIENT_ALIVE_INTERVAL}" "$cfg"
  set_or_add "ClientAliveCountMax" "${SSH_CLIENT_ALIVE_COUNT_MAX}" "$cfg"
  set_or_add "X11Forwarding" "no" "$cfg"
  set_or_add "AllowTcpForwarding" "no" "$cfg"
  set_or_add "AllowAgentForwarding" "no" "$cfg"
  set_or_add "PermitTunnel" "no" "$cfg"
  set_or_add "Banner" "${SSH_BANNER_FILE}" "$cfg"




  
  if ! grep -q "^Ciphers" "$cfg"; then
    set_or_add "Ciphers" "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" "$cfg"
  fi
  
  if ! grep -q "^MACs" "$cfg"; then
    set_or_add "MACs" "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256" "$cfg"
  fi
  
  if ! grep -q "^KexAlgorithms" "$cfg"; then
    set_or_add "KexAlgorithms" "curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256" "$cfg"
  fi

  sed -i "/^AllowUsers /d" "$cfg"
  local allow_users
  allow_users="$(printf '%s ' "${SSH_ALLOWED_USERS[@]}")"
  allow_users="${allow_users% }"
  echo "AllowUsers $allow_users" >> "$cfg"

  if [[ ! -d /run/sshd ]]; then
    mkdir -p /run/sshd
    chmod 0755 /run/sshd
  fi

  if sshd -t; then
    ok "sshd_config validation successful"
    systemctl restart ssh
    ok "SSH service restarted on port ${SSH_PORT}"
    warn "IMPORTANT: Test SSH connection on new port before closing this session!"
  else
    fail "Invalid sshd_config detected"
  fi
}

# =============================================================================
# FIREWALL
# =============================================================================
configure_firewall() {
  log "Configuring UFW firewall"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure firewall"
    return 0
  fi
  
  ufw --force reset &>>"$LOG_FILE"
  
  run ufw default deny incoming
  run ufw default allow outgoing
  run ufw logging on
  run ufw limit "${SSH_PORT}/tcp"
  
  for p in "${FIREWALL_ALLOWED_PORTS[@]}"; do
    [[ "$p" == "${SSH_PORT}/tcp" ]] && continue
    run ufw allow "$p"
  done
  
  run ufw --force enable
  
  ok "Firewall configured and enabled"
}

# =============================================================================
# FAIL2BAN
# =============================================================================
configure_fail2ban() {
  log "Configuring Fail2ban"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure Fail2ban"
    return 0
  fi
  
  cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd
action = %(action_mwl)s

[sshd]
enabled = true
port = ${SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

  systemctl enable fail2ban
  systemctl restart fail2ban
  
  ok "Fail2ban configured and enabled"
}

# =============================================================================
# GEO-IP BLOCKING
# =============================================================================
setup_geoip_blocking() {
  log "Setting up GeoIP blocking for Fail2ban"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would setup GeoIP blocking"
    return 0
  fi
  
  # Install geoip database
  if ! command_exists geoiplookup; then
    apt install -y geoip-bin geoip-database &>>"$LOG_FILE"
  fi
  
  # Create GeoIP filter
  cat > /etc/fail2ban/filter.d/geoip.conf << 'EOF'
[Definition]
failregex = ^.*<HOST>.*$
ignoreregex =
EOF

  # Create action script for GeoIP blocking
  cat > /etc/fail2ban/action.d/geoip.conf << 'EOF'
[Definition]
actionstart =
actionstop =
actioncheck =
actionban = COUNTRY=$(geoiplookup <ip> | awk -F ": " '{print $2}' | awk -F "," '{print $1}')
            if echo "CN RU KP IR PK BY" | grep -q "$COUNTRY"; then
                iptables -I INPUT -s <ip> -j DROP
            fi
actionunban = iptables -D INPUT -s <ip> -j DROP

[Init]
EOF

  # Update jail.local to use geoip
  if ! grep -q "\[geoip-sshd\]" /etc/fail2ban/jail.local; then
    cat >> /etc/fail2ban/jail.local << EOF

[geoip-sshd]
enabled = true
filter = geoip
action = geoip
logpath = /var/log/auth.log
maxretry = 1
bantime = -1
findtime = 86400
EOF
  fi
  
  systemctl restart fail2ban
  ok "GeoIP blocking configured for: ${BLOCKED_COUNTRIES[*]}"
}

# =============================================================================
# SYSCTL
# =============================================================================
configure_sysctl() {
  log "Configuring kernel parameters (sysctl)"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure sysctl"
    return 0
  fi
  
  local f="/etc/sysctl.d/99-hardening.conf"
  : > "$f"
  
  for k in "${!SYSCTL_CONF[@]}"; do
    echo "$k=${SYSCTL_CONF[$k]}" >> "$f"
  done
  
  run sysctl --system
  ok "Sysctl parameters applied"
}

# =============================================================================
# AUDITD
# =============================================================================
configure_auditd() {
  log "Configuring auditd"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure auditd"
    return 0
  fi
  
  cat > /etc/audit/rules.d/hardening.rules << 'EOF'
# Monitor changes to system files
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# Monitor SSH configuration
-w /etc/ssh/sshd_config -p wa -k sshd

# Monitor Docker
-w /usr/bin/docker -p x -k docker
-w /var/lib/docker -p wa -k docker

# Monitor sudo usage
-a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands
EOF

  systemctl enable auditd
  systemctl restart auditd
  
  ok "Auditd configured"
}

# =============================================================================
# UNATTENDED UPGRADES
# =============================================================================
configure_unattended_upgrades() {
  log "Configuring unattended-upgrades"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure unattended-upgrades"
    return 0
  fi
  
  cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=${distro_codename},label=Debian-Security";
    "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

  cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

  ok "Unattended-upgrades configured for security updates"
}

# =============================================================================
# LOGROTATE
# =============================================================================
configure_logrotate() {
  log "Configuring logrotate for custom applications"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure logrotate"
    return 0
  fi
  
  cat > /etc/logrotate.d/custom-apps << 'EOF'
/var/log/init_phase1.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
EOF

  ok "Logrotate configured"
}

# =============================================================================
# ENDLESSH (SSH TARPIT) - CORREGIDO
# =============================================================================
install_endlessh() {
  log "Installing endlessh SSH tarpit on port 22"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would install endlessh"
    return 0
  fi
  
  if command_exists endlessh; then
    ok "Endlessh already installed"
  else
    apt install -y endlessh &>>"$LOG_FILE"
  fi
  
  # Configure endlessh
  mkdir -p /etc/endlessh
  cat > /etc/endlessh/config << 'EOF'
# Port to bind to (default 2222, we use 22 as honeypot)
Port 22

# Delay in milliseconds between sending bytes
Delay 10000

# Maximum number of clients to accept at once
MaxClients 4096

# Maximum line length
MaxLineLength 32

# Log level (0 = quiet, 1 = standard, 2 = verbose)
LogLevel 1

# Bind family (0 = IPv4 only, 1 = IPv6 only, 2 = both)
BindFamily 0
EOF

  # Configure systemd service to allow binding to port 22
  mkdir -p /etc/systemd/system/endlessh.service.d
  cat > /etc/systemd/system/endlessh.service.d/override.conf << 'EOF'
[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
PrivateUsers=false
EOF

  # Set capabilities on endlessh binary
  setcap 'cap_net_bind_service=+ep' /usr/bin/endlessh
  
  # Reload systemd and enable/start endlessh
  systemctl daemon-reload
  systemctl enable endlessh
  systemctl restart endlessh
  
  ok "Endlessh installed and configured on port 22 with CAP_NET_BIND_SERVICE"
}

# =============================================================================
# CLAMAV - CORREGIDO
# =============================================================================
configure_clamav() {
  log "Configuring ClamAV antivirus"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure ClamAV"
    return 0
  fi
  
  # Stop, update and enable clamav-freshclam
  systemctl stop clamav-freshclam 2>/dev/null || true
  freshclam &>>"$LOG_FILE"
  systemctl enable clamav-freshclam
  systemctl start clamav-freshclam
  
  # Enable clamav-daemon
  systemctl enable clamav-daemon
  systemctl start clamav-daemon
  
  # Create daily scan script
  cat > /usr/local/bin/clamscan-daily << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/clamav/daily-scan.log"
SCAN_DIRS="/home /root /opt"

echo "=== ClamAV Daily Scan Started: $(date) ===" >> "$LOG_FILE"
clamscan -r -i --exclude-dir="^/sys" --exclude-dir="^/proc" --exclude-dir="^/dev" \
    $SCAN_DIRS >> "$LOG_FILE" 2>&1
echo "=== ClamAV Daily Scan Finished: $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
EOF

  chmod +x /usr/local/bin/clamscan-daily
  
  # Add to crontab (daily at 2 AM)
  if ! crontab -l 2>/dev/null | grep -q "clamscan-daily"; then
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/clamscan-daily") | crontab -
  fi
  
  ok "ClamAV configured with daily scans at 2 AM and enabled services"
}

# =============================================================================
# RKHUNTER
# =============================================================================
configure_rkhunter() {
  log "Configuring rkhunter for rootkit detection"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure rkhunter"
    return 0
  fi
  
  # Update rkhunter database
  rkhunter --update &>>"$LOG_FILE"
  rkhunter --propupd &>>"$LOG_FILE"
  
  # Configure rkhunter
  sed -i 's/^MAIL-ON-WARNING=.*/MAIL-ON-WARNING=""/' /etc/rkhunter.conf
  sed -i 's/^UPDATE_MIRRORS=.*/UPDATE_MIRRORS=1/' /etc/rkhunter.conf
  sed -i 's/^MIRRORS_MODE=.*/MIRRORS_MODE=0/' /etc/rkhunter.conf
  
  # Create weekly scan script
  cat > /usr/local/bin/rkhunter-weekly << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/rkhunter-weekly.log"

echo "=== Rkhunter Weekly Scan Started: $(date) ===" >> "$LOG_FILE"
rkhunter --check --skip-keypress --report-warnings-only >> "$LOG_FILE" 2>&1
echo "=== Rkhunter Weekly Scan Finished: $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Also run chkrootkit
echo "=== Chkrootkit Weekly Scan Started: $(date) ===" >> "$LOG_FILE"
chkrootkit >> "$LOG_FILE" 2>&1
echo "=== Chkrootkit Weekly Scan Finished: $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
EOF

  chmod +x /usr/local/bin/rkhunter-weekly
  
  # Add to crontab (weekly on Sunday at 3 AM)
  if ! crontab -l 2>/dev/null | grep -q "rkhunter-weekly"; then
    (crontab -l 2>/dev/null; echo "0 3 * * 0 /usr/local/bin/rkhunter-weekly") | crontab -
  fi
  
  ok "Rkhunter and chkrootkit configured with weekly scans"
}

# =============================================================================
# FORTRESS HARDENING SCRIPT
# =============================================================================
download_fortress_script() {
  log "Downloading fortress_improved.sh hardening script"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would download from: ${FORTRESS_SCRIPT_URL}"
    return 0
  fi
  
  if [[ -f "$FORTRESS_SCRIPT" ]]; then
    ok "Fortress script already exists at $FORTRESS_SCRIPT"
    return 0
  fi
  
  if wget -q -O "$FORTRESS_SCRIPT" "$FORTRESS_SCRIPT_URL"; then
    chmod +x "$FORTRESS_SCRIPT"
    ok "Fortress script downloaded to $FORTRESS_SCRIPT"
    log ""
    log "To run additional hardening, execute:"
    log "  cd /root && ./fortress_improved.sh -l high -n --explain"
    log ""
  else
    warn "Failed to download fortress script from $FORTRESS_SCRIPT_URL"
  fi
}

# =============================================================================
# DOCUMENTATION
# =============================================================================
generate_documentation() {
  log "Generating setup documentation"
  
  local doc_file="/root/SETUP_INFO.txt"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would generate documentation"
    return 0
  fi
  
  cat > "$doc_file" << EOF
╔═══════════════════════════════════════════════════════════════════════════╗
║                    DEBIAN 13 VPS SETUP DOCUMENTATION                       ║
╚═══════════════════════════════════════════════════════════════════════════╝

Setup Date: $(date '+%Y-%m-%d %H:%M:%S')
Hostname: $(hostname)

═══════════════════════════════════════════════════════════════════════════
SSH CONFIGURATION
═══════════════════════════════════════════════════════════════════════════
SSH Port: ${SSH_PORT}
Allowed Users: $(join_by ', ' "${SSH_ALLOWED_USERS[@]}")
Password Authentication: DISABLED
Root Login: DISABLED
Login Banner: ENABLED

⚠️  IMPORTANT: Connect using: ssh -p ${SSH_PORT} user@$(hostname -I | awk '{print $1}')

═══════════════════════════════════════════════════════════════════════════
SECURITY FEATURES
═══════════════════════════════════════════════════════════════════════════
✓ Fail2ban: ENABLED (SSH protection on port ${SSH_PORT})
✓ GeoIP Blocking: ENABLED (Countries: ${BLOCKED_COUNTRIES[*]})
✓ SSH Tarpit (endlessh): Port 22
✓ UFW Firewall: ENABLED
✓ Auditd: ENABLED (monitoring /etc, sudo, docker)
✓ Unattended Security Updates: ENABLED
✓ Kernel Hardening: Applied (sysctl)
✓ ClamAV: Daily scans at 2 AM
✓ Rkhunter/Chkrootkit: Weekly scans on Sunday at 3 AM

═══════════════════════════════════════════════════════════════════════════
FIREWALL (UFW)
═══════════════════════════════════════════════════════════════════════════
Status: ENABLED
Allowed Ports: $(join_by ', ' "${FIREWALL_ALLOWED_PORTS[@]}")
SSH Rate Limiting: ENABLED (port ${SSH_PORT})

═══════════════════════════════════════════════════════════════════════════
DOCKER
═══════════════════════════════════════════════════════════════════════════
Docker Version: $(docker --version 2>/dev/null || echo "Not installed")
Docker Compose: $(docker compose version 2>/dev/null || echo "Not installed")

Docker Deploy Group: ${DOCKER_DEPLOY_GROUP}
Projects Directory: ${DOCKER_DEPLOY_BASE_DIR}

Helper Scripts:
  - docker-deploy (alias: dp) - Deploy and manage compose files
  - docker-manage (alias: dm) - Manage containers and images

Helper Commands:
  dp start <compose-file>   - Start containers
  dp stop <compose-file>    - Stop containers
  dp restart <compose-file> - Restart containers
  dp logs <compose-file>    - View logs
  dp pull <compose-file>    - Pull latest images
  
  dm ps                     - List containers
  dm images                 - List images
  dm prune                  - Clean unused resources
  dm stats                  - Show resource usage
  dm logs <container>       - View container logs

═══════════════════════════════════════════════════════════════════════════
SYSTEM CONFIGURATION
═══════════════════════════════════════════════════════════════════════════
Timezone: ${TIMEZONE}
Swap: ${SWAP_SIZE} at ${SWAP_FILE}
Locale: en_US.UTF-8, es_ES.UTF-8

═══════════════════════════════════════════════════════════════════════════
USERS CREATED
═══════════════════════════════════════════════════════════════════════════
EOF

  for entry in "${USERS[@]}"; do
    IFS=":" read -r user pass sshkey <<<"$entry"
    echo "  - $user (member of ${DOCKER_DEPLOY_GROUP})" >> "$doc_file"
  done

  cat >> "$doc_file" << EOF

═══════════════════════════════════════════════════════════════════════════
BACKUP INFORMATION
═══════════════════════════════════════════════════════════════════════════
Configuration backups location: /root/config_backup_*
Log file: ${LOG_FILE}

═══════════════════════════════════════════════════════════════════════════
SCHEDULED TASKS
═══════════════════════════════════════════════════════════════════════════
Daily 2 AM:  ClamAV virus scan
Weekly Sun 3 AM: Rkhunter/Chkrootkit rootkit scan

═══════════════════════════════════════════════════════════════════════════
ADDITIONAL HARDENING
═══════════════════════════════════════════════════════════════════════════
Fortress hardening script: ${FORTRESS_SCRIPT}

To apply additional hardening, run:
  cd /root
  ./fortress_improved.sh -l high -n --explain

After running fortress, reconfigure services with:
  ./debian13_init.sh (option 7: Reconfigure services)

═══════════════════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════════════════
1. Test SSH connection on port ${SSH_PORT} BEFORE closing this session
2. Run additional hardening: ./fortress_improved.sh -l high -n --explain
3. Reconfigure services after fortress: ./debian13_init.sh (option 7)
4. Deploy Docker containers in ${DOCKER_DEPLOY_BASE_DIR}
5. Configure monitoring/alerting as needed

═══════════════════════════════════════════════════════════════════════════
USEFUL COMMANDS
═══════════════════════════════════════════════════════════════════════════
Check Fail2ban status:  fail2ban-client status sshd
Check firewall status:  ufw status verbose
Check Docker status:    dm ps
View audit logs:        ausearch -k docker
View system logs:       journalctl -xe
Check ClamAV logs:      tail -f /var/log/clamav/daily-scan.log
Check Rkhunter logs:    tail -f /var/log/rkhunter-weekly.log

Docker aliases (available after login):
  dp - docker-deploy
  dm - docker-manage

═══════════════════════════════════════════════════════════════════════════
EOF

  chmod 600 "$doc_file"
  ok "Documentation generated: $doc_file"
}

# =============================================================================
# FINAL CHECKS
# =============================================================================
final_security_check() {
  log "Performing final security verification"
  
  local issues=0
  
  if systemctl is-active --quiet ssh; then
    ok "SSH service is running"
  else
    warn "SSH service is not running"
    ((issues++))
  fi
  
  if ufw status 2>/dev/null | grep -q "Status: active"; then
    ok "Firewall is active"
  else
    warn "Firewall is not active"
    ((issues++))
  fi
  
  if systemctl is-active --quiet fail2ban; then
    ok "Fail2ban is running"
  else
    warn "Fail2ban is not running"
    ((issues++))
  fi
  
  if command_exists docker; then
    ok "Docker is installed"
    if systemctl is-active --quiet docker; then
      ok "Docker service is running"
    else
      warn "Docker service is not running"
      ((issues++))
    fi
  else
    warn "Docker is not installed"
    ((issues++))
  fi
  
  if swapon --show | grep -q "$SWAP_FILE"; then
    ok "Swap is active"
  else
    warn "Swap is not active"
    ((issues++))
  fi
  
  if getent group "${DOCKER_DEPLOY_GROUP}" >/dev/null; then
    ok "Docker deploy group exists"
  else
    warn "Docker deploy group missing"
    ((issues++))
  fi
  
  if [[ -d "$DOCKER_DEPLOY_BASE_DIR" ]]; then
    ok "Docker projects directory exists"
  else
    warn "Docker projects directory missing"
    ((issues++))
  fi
  
  if systemctl is-active --quiet endlessh; then
    ok "Endlessh tarpit is running"
  else
    warn "Endlessh is not running"
  fi
  
  if systemctl is-active --quiet clamav-freshclam; then
    ok "ClamAV freshclam is running"
  else
    warn "ClamAV freshclam is not running"
  fi
  
  if systemctl is-active --quiet clamav-daemon; then
    ok "ClamAV daemon is running"
  else
    warn "ClamAV daemon is not running"
  fi
  
  if [[ $issues -eq 0 ]]; then
    ok "All critical security checks passed ✓"
  else
    warn "Found $issues issues - review logs"
  fi
}

# =============================================================================
# SERVICE RESTART AND VALIDATION
# =============================================================================
restart_and_validate_services() {
  log ""
  log "╔═══════════════════════════════════════════════════════════════════════╗"
  log "║                  RESTARTING AND VALIDATING SERVICES                       ║"
  log "╚═══════════════════════════════════════════════════════════════════════╝"
  log ""
  
  # Reconfigure SSH
  log "Reconfiguring SSH service..."
  configure_ssh
  
  # Validate SSH
  if ss -tlnp | grep -q ":${SSH_PORT}"; then
    ok "SSH is listening on port ${SSH_PORT}"
  else
    warn "SSH is NOT listening on port ${SSH_PORT}"
  fi
  
  # Reconfigure and restart fail2ban
  log "Reconfiguring Fail2ban..."
  configure_fail2ban
  
  if systemctl is-active --quiet fail2ban; then
    ok "Fail2ban is active"
    fail2ban-client status | sed 's/^/  /'
  else
    warn "Fail2ban failed to start"
  fi
  
  # Reconfigure and restart UFW
  log "Reconfiguring UFW firewall..."
  configure_firewall
  
  if ufw status | grep -q "Status: active"; then
    ok "UFW is active"
  else
    warn "UFW is not active"
  fi
  
  # Restart endlessh
  if systemctl is-active --quiet endlessh; then
    systemctl restart endlessh
    ok "Endlessh restarted"
  fi
  
  log ""
  log "╔═══════════════════════════════════════════════════════════════════════╗"
  log "║                    SERVICE VALIDATION COMPLETE                            ║"
  log "╚═══════════════════════════════════════════════════════════════════════╝"
  log ""
  log "⚠️  IMPORTANT: Test SSH connection now!"
  log "   From another terminal: ssh -p ${SSH_PORT} user@$(hostname -I | awk '{print $1}')"
  log ""
}

# =============================================================================
# CHECK FUNCTIONS (for menu option 2) - ACTUALIZADO
# =============================================================================
check_fail2ban() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║  FAIL2BAN STATUS                                           ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  
  if ! command_exists fail2ban-client; then
    log "  ✗ Fail2ban not installed"
    return
  fi

  if ! systemctl is-active --quiet fail2ban; then
    log "  ✗ Fail2ban installed but inactive"
    return
  fi

  log "  ✓ Active"
  log ""
  log "  SSH Jail Status:"
  fail2ban-client status sshd 2>/dev/null | sed 's/^/    /' || log "    No SSH jail configured"
  log ""
}

check_ssh_logins() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║  RECENT SSH LOGINS (last 24h)                              ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  
  if journalctl -u ssh --since "24 hours ago" 2>/dev/null | grep -q "Accepted"; then
    journalctl -u ssh --since "24 hours ago" \
      | grep "Accepted" \
      | tail -n 10 \
      | sed 's/^/  /'
  else
    log "  No successful logins in the last 24 hours"
  fi
  log ""
}

check_disk_usage() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║  DISK USAGE                                                ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  
  df -h / /var 2>/dev/null | awk 'NR==1 || NR>1 {printf "  %-20s %8s %8s %8s %5s\n", $6, $2, $3, $4, $5}'
  log ""
}

check_memory_usage() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║  MEMORY USAGE                                              ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  
  free -h | awk '
    NR==1 {printf "  %-10s %8s %8s %8s\n", "", $2, $3, $4}
    NR==2 {printf "  %-10s %8s %8s %8s\n", "Memory:", $2, $3, $4}
    NR==3 {printf "  %-10s %8s %8s %8s\n", "Swap:", $2, $3, $4}
  '
  log ""
}

check_docker_status() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║  DOCKER STATUS                                             ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  
  if ! command_exists docker; then
    log "  ✗ Docker not installed"
    return
  fi
  
  if systemctl is-active --quiet docker; then
    log "  ✓ Docker service: Active"
    log "  ✓ Deploy group: ${DOCKER_DEPLOY_GROUP}"
    log "  ✓ Projects dir: ${DOCKER_DEPLOY_BASE_DIR}"
    log ""
    log "  Running Containers:"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | tail -n +2 | grep -q .; then
      docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed 's/^/    /'
    else
      log "    No containers running"
    fi
  else
    log "  ✗ Docker service: Inactive"
  fi
  log ""
}

check_firewall_status() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║  FIREWALL STATUS                                           ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  
  if command_exists ufw; then
    ufw status verbose 2>/dev/null | sed 's/^/  /'
  else
    log "  ✗ UFW not installed"
  fi
  log ""
}

check_security_updates() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║  SECURITY UPDATES                                          ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  
  apt update &>/dev/null
  local updates
  updates=$(apt list --upgradable 2>/dev/null | grep -c "security" || echo "0")
  
  if [[ "$updates" =~ ^[0-9]+$ ]] && [[ $updates -gt 0 ]]; then
    log "  ⚠  $updates security updates available"
    log "  Run: apt upgrade"
  else
    log "  ✓ System is up to date"
  fi
  log ""
}

check_security_services() {
  log ""
  log "╔═══════════════════════════════════════════════════════════╗"
  log "║  SECURITY SERVICES                                         ║"
  log "╚═══════════════════════════════════════════════════════════╝"
  
  # Check endlessh
  if systemctl is-active --quiet endlessh; then
    log "  ✓ Endlessh (SSH tarpit): Active on port 22"
  else
    log "  ✗ Endlessh: Inactive"
  fi
  
  # Check ClamAV freshclam
  if systemctl is-active --quiet clamav-freshclam; then
    log "  ✓ ClamAV Freshclam: Active"
  else
    log "  ✗ ClamAV Freshclam: Inactive"
  fi
  
  # Check ClamAV daemon
  if systemctl is-active --quiet clamav-daemon; then
    log "  ✓ ClamAV Daemon: Active (daily scans at 2 AM)"
  else
    log "  ✗ ClamAV Daemon: Inactive"
  fi
  
  # Check if rkhunter is configured
  if [[ -f /usr/local/bin/rkhunter-weekly ]]; then
    log "  ✓ Rkhunter: Configured (weekly scans)"
  else
    log "  ✗ Rkhunter: Not configured"
  fi
  
  log ""
}

run_checks() {
  log ""
  log "═══════════════════════════════════════════════════════════════════════"
  log "                          SYSTEM STATUS CHECK"
  log "═══════════════════════════════════════════════════════════════════════"
  
  check_disk_usage
  check_memory_usage
  check_docker_status
  check_firewall_status
  check_fail2ban
  check_security_services
  check_ssh_logins
  check_security_updates
  
  log "═══════════════════════════════════════════════════════════════════════"
  log ""
}

# =============================================================================
# MAIN EXECUTION ENGINE
# =============================================================================
run_setup() {
  log ""
  log "╔═══════════════════════════════════════════════════════════════════════╗"
  log "║                    STARTING VPS SETUP & HARDENING                         ║"
  log "╚═══════════════════════════════════════════════════════════════════════╝"
  log ""
  
  local last_step current=0
  last_step="$(load_last_step)"

  if [[ $last_step -gt 0 ]]; then
    log "Resuming from step $last_step (previous run detected)"
  fi

  for fn in "${STEPS[@]}"; do
    current=$((current + 1))
    
    if (( current <= last_step )); then
      log "[$current/$STEP_TOTAL] ⊘ Skipping $fn (already completed)"
      continue
    fi

    log ""
    log "[$current/$STEP_TOTAL] ▶ Executing: $fn"
    log "────────────────────────────────────────────────────────────────"
    
    if "$fn"; then
      save_last_step "$current"
      ok "[$current/$STEP_TOTAL] ✓ Completed: $fn"
    else
      fail "[$current/$STEP_TOTAL] ✗ Failed: $fn"
    fi
  done

  log ""
  log "╔═══════════════════════════════════════════════════════════════════════╗"
  log "║                    ✓ PHASE 1 COMPLETED SUCCESSFULLY                       ║"
  log "╚═══════════════════════════════════════════════════════════════════════╝"
  log ""
  log "📄 Documentation: /root/SETUP_INFO.txt"
  log "📋 Log file: ${LOG_FILE}"
  log ""
  log "⚠️  CRITICAL: Test SSH access on port ${SSH_PORT} before closing this session!"
  log ""
  log "Next: Run additional hardening with:"
  log "  cd /root && ./fortress_improved.sh -l high -n --explain"
  log ""
  log "After fortress, reconfigure services with option 7 in the menu"
  log ""
  
  # Clean up state file if in dry-run mode
  if $DRY_RUN && [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
    log "Dry-run complete - state file removed"
  fi
}

# =============================================================================
# COMMAND LINE FLAGS
# =============================================================================
NO_MENU=false

for arg in "$@"; do
  case "$arg" in
    --no-menu)
      NO_MENU=true
      ;;
    --dry-run)
      DRY_RUN=true
      log "DRY-RUN mode enabled - no changes will be made"
      ;;
    --help|-h)
      cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
  --no-menu    Run setup automatically without menu
  --dry-run    Show what would be done without making changes
  --help, -h   Show this help message

EXAMPLES:
  $0                    # Interactive menu
  $0 --no-menu          # Run setup automatically
  $0 --dry-run          # Preview changes without applying

EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# =============================================================================
# MENU - ACTUALIZADO (Exit = 0)
# =============================================================================
main_menu() {
  while true; do
    clear
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                   Debian 13 VPS Init & Hardening                          ║"
    echo "║                           Version 1.1                                     ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  1) 🚀 Run full setup & hardening"
    echo "  2) 📊 Check system status"
    echo "  3) 📋 View documentation"
    echo "  4) 🧪 Dry-run (preview changes)"
    echo "  5) 🔒 Run fortress hardening"
    echo "  6) 🗑️  Clear progress & restart from beginning"
    echo "  7) 🔄 Reconfigure services (SSH, Fail2ban, UFW)"
    echo "  0) 🚪 Exit"
    echo ""
    echo "────────────────────────────────────────────────────────────────────"
    echo ""
    read -rp "Select an option [0-7]: " choice

    case "$choice" in
      1)
        run_setup
        echo ""
        read -rp "Press Enter to continue..."
        ;;
      2)
        run_checks
        echo ""
        read -rp "Press Enter to continue..."
        ;;
      3)
        if [[ -f /root/SETUP_INFO.txt ]]; then
          clear
          cat /root/SETUP_INFO.txt
          echo ""
          read -rp "Press Enter to continue..."
        else
          echo ""
          echo "Documentation not found. Run setup first."
          sleep 2
        fi
        ;;
      4)
        DRY_RUN=true
        run_setup
        DRY_RUN=false
        echo ""
        read -rp "Press Enter to continue..."
        ;;
      5)
        if [[ -f "$FORTRESS_SCRIPT" ]]; then
          echo ""
          echo "Running fortress hardening script..."
          echo "This will apply additional security measures."
          echo ""
          read -rp "Continue? [y/N]: " confirm
          if [[ "$confirm" =~ ^[Yy]$ ]]; then
            cd /root
            bash ./fortress_improved.sh -l high -n --explain
            echo ""
            echo "⚠️  IMPORTANT: Fortress may have changed SSH/Firewall configs."
            echo "   Run option 7 to reconfigure services with your custom settings."
          fi
          echo ""
          read -rp "Press Enter to continue..."
        else
          echo ""
          echo "Fortress script not found. Run setup first (option 1)."
          sleep 2
        fi
        ;;
      6)
        echo ""
        echo "⚠️  WARNING: This will clear all progress and allow you to restart."
        echo "   Current configuration will remain, but setup tracking will be reset."
        echo ""
        read -rp "Are you sure? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          clear_last_step
        else
          echo "Cancelled."
        fi
        echo ""
        read -rp "Press Enter to continue..."
        ;;
      7)
        echo ""
        echo "Reconfiguring critical services..."
        echo "This will reapply SSH, Fail2ban, and UFW configurations."
        echo ""
        read -rp "Continue? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          restart_and_validate_services
        else
          echo "Cancelled."
        fi
        echo ""
        read -rp "Press Enter to continue..."
        ;;
      0)
        log "Exiting"
        exit 0
        ;;
      *)
        echo "Invalid option"
        sleep 1
        ;;
    esac
  done
}

# =============================================================================
# MAIN
# =============================================================================
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

log "═══════════════════════════════════════════════════════════════════════"
log "Script started: $(date '+%Y-%m-%d %H:%M:%S')"
log "User: $(whoami) | Hostname: $(hostname)"
log "═══════════════════════════════════════════════════════════════════════"

if $NO_MENU; then
  log "Running in non-interactive mode (--no-menu)"
  run_setup
  run_checks
else
  main_menu
fi

log "═══════════════════════════════════════════════════════════════════════"
log "Script finished: $(date '+%Y-%m-%d %H:%M:%S')"
log "═══════════════════════════════════════════════════════════════════════"