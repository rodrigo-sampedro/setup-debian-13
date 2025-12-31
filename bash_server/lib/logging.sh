#!/usr/bin/env bash
# =============================================================================
# lib/logging.sh - Sistema de Logging
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