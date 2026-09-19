#!/usr/bin/env bash
# =============================================================================
# modules/checks.sh - Funciones de Verificación del Sistema
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