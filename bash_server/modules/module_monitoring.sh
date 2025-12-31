#!/usr/bin/env bash
# =============================================================================
# modules/monitoring.sh - Monitoreo: ClamAV, Rkhunter, Auditd
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
  ./setup_debian13.sh (option 7: Reconfigure services)

═══════════════════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════════════════
1. Test SSH connection on port ${SSH_PORT} BEFORE closing this session
2. Run additional hardening: ./fortress_improved.sh -l high -n --explain
3. Reconfigure services after fortress: ./setup_debian13.sh (option 7)
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