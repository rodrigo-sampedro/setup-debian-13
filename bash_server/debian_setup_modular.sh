#!/usr/bin/env bash
# =============================================================================
# ESTRUCTURA MODULAR - Debian 13 VPS Setup
# =============================================================================

# Estructura de directorios:
#
# setup_debian13/
# ├── setup_debian13.sh           # Main entry point (este archivo)
# ├── lib/
# │   ├── config.sh              # Configuración global
# │   ├── logging.sh             # Sistema de logging
# │   └── utils.sh               # Utilidades comunes
# ├── modules/
# │   ├── system.sh              # Configuración del sistema
# │   ├── users.sh               # Gestión de usuarios
# │   ├── docker.sh              # Docker y contenedores
# │   ├── security.sh            # SSH, firewall, fail2ban
# │   ├── monitoring.sh          # ClamAV, rkhunter, auditd
# │   └── checks.sh              # Funciones de verificación
# ├── compile.sh                 # Compilador para generar versión única
# └── README.md

# =============================================================================
# ARCHIVO: setup_debian13.sh (MAIN)
# =============================================================================
set -Eeuo pipefail
IFS=$'\n\t'

# Detectar directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cargar librerías
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/utils.sh"

# Cargar módulos
source "${SCRIPT_DIR}/modules/system.sh"
source "${SCRIPT_DIR}/modules/users.sh"
source "${SCRIPT_DIR}/modules/docker.sh"
source "${SCRIPT_DIR}/modules/security.sh"
source "${SCRIPT_DIR}/modules/monitoring.sh"
source "${SCRIPT_DIR}/modules/checks.sh"

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
# MENU
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