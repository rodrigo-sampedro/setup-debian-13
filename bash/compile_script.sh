#!/usr/bin/env bash
#===============================================================================
# compile.sh - Compilador para generar setup_debian13.sh único
#===============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="setup_debian13_compiled.sh"
VERSION="1.1"

echo "═══════════════════════════════════════════════════════════════"
echo "  Debian 13 Setup - Script Compiler v${VERSION}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Verificar estructura de directorios
if [[ ! -d "$SCRIPT_DIR/lib" ]] || [[ ! -d "$SCRIPT_DIR/modules" ]]; then
    echo "❌ Error: Directories 'lib/' and 'modules/' must exist"
    exit 1
fi

echo "📁 Checking structure..."
echo "   ✓ lib/ found"
echo "   ✓ modules/ found"
echo ""

# Verificar archivos requeridos
REQUIRED_FILES=(
    "lib/config.sh"
    "lib/logging.sh"
    "lib/utils.sh"
    "modules/system.sh"
    "modules/users.sh"
    "modules/docker.sh"
    "modules/security.sh"
    "modules/monitoring.sh"
    "modules/checks.sh"
)

echo "🔍 Checking required files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
        echo "   ❌ Missing: $file"
        exit 1
    fi
    echo "   ✓ $file"
done
echo ""

echo "🔨 Compiling script..."
echo ""

# Crear archivo de salida con header
cat > "$OUTPUT_FILE" << 'HEADER'
#!/usr/bin/env bash
#===============================================================================
# Script Name       : setup_debian13.sh (COMPILED)
# Description       : Debian 13 Setup VPS Users, ssh, fail2ban ufw and docker
# Author            : Rodrigo Sampedro Casis
# Creation date     : 2025-12-26
# Version           : 1.1
# Usage             : ./setup_debian13.sh [--no-menu] [--dry-run]
#===============================================================================
set -Eeuo pipefail
IFS=$'\n\t'

HEADER

# Función para extraer contenido sin shebang ni set
extract_content() {
    local file="$1"
    grep -v '^#!/usr/bin/env bash' "$file" | \
    grep -v '^set -' | \
    grep -v '^IFS=' | \
    sed '/^# ===.*===$/,/^# ===.*===$/{ /^# ===/d; }' | \
    sed '/^$/N;/^\n$/d'
}

# Añadir sección de configuración
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "# CONFIGURATION" >> "$OUTPUT_FILE"
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_content "$SCRIPT_DIR/lib/config.sh" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Añadir sistema de logging
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "# LOGGING CORE" >> "$OUTPUT_FILE"
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_content "$SCRIPT_DIR/lib/logging.sh" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Añadir utilidades
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "# UTILITY FUNCTIONS" >> "$OUTPUT_FILE"
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_content "$SCRIPT_DIR/lib/utils.sh" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Añadir módulos
for module in system users docker security monitoring; do
    if [[ -f "$SCRIPT_DIR/modules/${module}.sh" ]]; then
        echo "# =============================================================================" >> "$OUTPUT_FILE"
        echo "# MODULE: $(echo $module | tr '[:lower:]' '[:upper:]')" >> "$OUTPUT_FILE"
        echo "# =============================================================================" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        extract_content "$SCRIPT_DIR/modules/${module}.sh" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Añadir módulo de checks
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "# CHECK FUNCTIONS" >> "$OUTPUT_FILE"
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_content "$SCRIPT_DIR/modules/checks.sh" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Añadir el main del script original
echo "# =============================================================================" >> "$OUTPUT_FILE"
echo "# STEPS DEFINITION" >> "$OUTPUT_FILE"
echo "# =============================================================================" >> "$OUTPUT_FILE"
cat >> "$OUTPUT_FILE" << 'STEPS'
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

STEPS

# Añadir engine de ejecución y menú principal
cat >> "$OUTPUT_FILE" << 'MAIN'

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
MAIN

# Hacer ejecutable
chmod +x "$OUTPUT_FILE"

echo "✅ Compilation successful!"
echo ""
echo "Output file: $OUTPUT_FILE"
echo "Size: $(wc -l < "$OUTPUT_FILE") lines"
echo ""
echo "You can now use:"
echo "  ./$OUTPUT_FILE                # Run with interactive menu"
echo "  ./$OUTPUT_FILE --no-menu      # Run automatically"
echo "  ./$OUTPUT_FILE --dry-run      # Preview changes"
echo ""
echo "To distribute:"
echo "  curl -fsSL https://your-url/$OUTPUT_FILE | bash"
echo ""
echo "═══════════════════════════════════════════════════════════════"