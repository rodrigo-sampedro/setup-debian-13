#!/usr/bin/env bash
# =============================================================================
# lib/config.sh - Configuración Global
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