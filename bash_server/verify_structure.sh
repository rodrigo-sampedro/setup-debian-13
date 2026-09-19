#!/usr/bin/env bash
#===============================================================================
# verify_structure.sh - Verifica la estructura modular del proyecto
#===============================================================================
set -euo pipefail

PROJECT_DIR="setup_debian13"
ERRORS=0
WARNINGS=0

echo "═══════════════════════════════════════════════════════════════"
echo "  Verifying Modular Structure - Debian 13 Setup"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Verificar que existe el directorio del proyecto
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "❌ ERROR: Directory '$PROJECT_DIR' does not exist"
    echo "   Run setup_structure.sh first"
    exit 1
fi

cd "$PROJECT_DIR"

# Lista de archivos requeridos
REQUIRED_FILES=(
    "setup_debian13.sh:Main entry point:755"
    "compile.sh:Compiler script:755"
    "README.md:Documentation:644"
    "lib/config.sh:Configuration:644"
    "lib/logging.sh:Logging system:644"
    "lib/utils.sh:Utilities:644"
    "modules/system.sh:System configuration:644"
    "modules/users.sh:User management:644"
    "modules/docker.sh:Docker setup:644"
    "modules/security.sh:Security configuration:644"
    "modules/monitoring.sh:Monitoring setup:644"
    "modules/checks.sh:System checks:644"
)

echo "📋 Checking required files..."
echo ""

for entry in "${REQUIRED_FILES[@]}"; do
    IFS=":" read -r file desc perms <<< "$entry"
    
    if [[ -f "$file" ]]; then
        # Verificar tamaño
        size=$(wc -l < "$file")
        if [[ $size -lt 10 ]]; then
            echo "⚠️  WARNING: $file exists but seems empty ($size lines)"
            echo "            Description: $desc"
            ((WARNINGS++))
        else
            echo "✓ $file ($size lines)"
        fi
        
        # Verificar permisos sugeridos
        current_perms=$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file" 2>/dev/null)
        if [[ "$current_perms" != "$perms" ]]; then
            echo "  ⚠️  Permissions: $current_perms (suggested: $perms)"
            echo "     Fix with: chmod $perms $file"
        fi
    else
        echo "❌ MISSING: $file"
        echo "           Description: $desc"
        ((ERRORS++))
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"

# Verificar funciones clave en cada módulo
echo ""
echo "🔍 Checking key functions in modules..."
echo ""

declare -A EXPECTED_FUNCTIONS=(
    ["lib/config.sh"]="SSH_PORT USERS FIREWALL_ALLOWED_PORTS"
    ["lib/logging.sh"]="log warn fail ok"
    ["lib/utils.sh"]="command_exists check_privileges show_configuration"
    ["modules/system.sh"]="configure_timezone configure_swap configure_sysctl"
    ["modules/users.sh"]="create_users setup_ssh_keys configure_sudo"
    ["modules/docker.sh"]="install_docker configure_docker_daemon setup_docker_projects_dir"
    ["modules/security.sh"]="configure_ssh configure_firewall install_endlessh"
    ["modules/monitoring.sh"]="configure_clamav configure_rkhunter configure_auditd"
    ["modules/checks.sh"]="check_fail2ban check_docker_status run_checks"
)

for file in "${!EXPECTED_FUNCTIONS[@]}"; do
    if [[ -f "$file" ]]; then
        missing=""
        for func in ${EXPECTED_FUNCTIONS[$file]}; do
            if ! grep -q "$func" "$file"; then
                missing="${missing}${func} "
            fi
        done
        
        if [[ -z "$missing" ]]; then
            echo "  ✓ $file - All key functions present"
        else
            echo "  ⚠️  $file - Missing: $missing"
            ((WARNINGS++))
        fi
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Verificar sintaxis bash en archivos .sh
echo "🔧 Checking bash syntax..."
echo ""

for file in setup_debian13.sh compile.sh lib/*.sh modules/*.sh; do
    if [[ -f "$file" ]]; then
        if bash -n "$file" 2>/dev/null; then
            echo "  ✓ $file - Syntax OK"
        else
            echo "  ❌ $file - Syntax ERROR"
            bash -n "$file"
            ((ERRORS++))
        fi
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Resumen
echo "📊 VERIFICATION SUMMARY"
echo ""
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo "✅ Structure is complete and ready to use!"
    echo ""
    echo "Next steps:"
    echo "  1. Test modular version:  ./setup_debian13.sh --dry-run"
    echo "  2. Compile single file:   ./compile.sh"
    echo "  3. Test compiled version: ./setup_debian13_compiled.sh --dry-run"
    echo ""
elif [[ $ERRORS -eq 0 ]]; then
    echo "⚠️  Structure is complete but has warnings."
    echo "   Review warnings above and fix if necessary."
    echo ""
elif [[ $ERRORS -gt 0 ]]; then
    echo "❌ Structure is incomplete. Fix errors above before proceeding."
    echo ""
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"