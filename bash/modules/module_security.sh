#!/usr/bin/env bash
# =============================================================================
# modules/security.sh - Seguridad: SSH, Firewall, Fail2ban, Endlessh
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

configure_ssh() {
  log "Hardening SSH configuration"

  local cfg="/etc/ssh/sshd_config"

  if $DRY_RUN; then
    log "[DRY-RUN] Would harden SSH configuration"
    return 0
  fi

  cp "$cfg" "${cfg}.bak.$(date +%s)"

  sed -i "s/^#\?Port .*/Port ${SSH_PORT}/" "$cfg"
  sed -i "s/^#\?PermitRootLogin .*/PermitRootLogin no/" "$cfg"
  sed -i "s/^#\?PasswordAuthentication .*/PasswordAuthentication no/" "$cfg"
  sed -i "s/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/" "$cfg"
  sed -i "s/^#\?PermitEmptyPasswords .*/PermitEmptyPasswords no/" "$cfg"
  sed -i "s/^#\?MaxAuthTries .*/MaxAuthTries ${SSH_MAX_AUTH_TRIES}/" "$cfg"
  sed -i "s/^#\?MaxSessions .*/MaxSessions ${SSH_MAX_SESSIONS}/" "$cfg"
  sed -i "s/^#\?ClientAliveInterval .*/ClientAliveInterval ${SSH_CLIENT_ALIVE_INTERVAL}/" "$cfg"
  sed -i "s/^#\?ClientAliveCountMax .*/ClientAliveCountMax ${SSH_CLIENT_ALIVE_COUNT_MAX}/" "$cfg"
  sed -i "s/^#\?X11Forwarding .*/X11Forwarding no/" "$cfg"
  sed -i "s/^#\?AllowTcpForwarding .*/AllowTcpForwarding no/" "$cfg"
  sed -i "s/^#\?AllowAgentForwarding .*/AllowAgentForwarding no/" "$cfg"
  sed -i "s/^#\?PermitTunnel .*/PermitTunnel no/" "$cfg"
  
  # Banner
  sed -i "s|^#\?Banner .*|Banner ${SSH_BANNER_FILE}|" "$cfg"
  
  if ! grep -q "^Ciphers" "$cfg"; then
    echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" >> "$cfg"
  fi
  
  if ! grep -q "^MACs" "$cfg"; then
    echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256" >> "$cfg"
  fi
  
  if ! grep -q "^KexAlgorithms" "$cfg"; then
    echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256" >> "$cfg"
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