#!/usr/bin/env bash
# =============================================================================
# lib/utils.sh - Utilidades Comunes
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