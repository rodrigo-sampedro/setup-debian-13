#!/usr/bin/env bash
# =============================================================================
# modules/system.sh - Configuración del Sistema
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
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab"
  fi
  
  ok "Swap configured and enabled"
}

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