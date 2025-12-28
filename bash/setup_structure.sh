#!/usr/bin/env bash
#===============================================================================
# setup_structure.sh - Crea la estructura modular del proyecto
#===============================================================================
set -euo pipefail

PROJECT_DIR="setup_debian13"

echo "═══════════════════════════════════════════════════════════════"
echo "  Creating Modular Structure for Debian 13 Setup"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Crear estructura de directorios
echo "📁 Creating directory structure..."
mkdir -p "${PROJECT_DIR}"/{lib,modules}
cd "${PROJECT_DIR}"

echo "   ✓ Created ${PROJECT_DIR}/lib/"
echo "   ✓ Created ${PROJECT_DIR}/modules/"
echo ""

# Copiar archivos que ya tienes
echo "📋 Instructions:"
echo ""
echo "Now you need to create the following files in ${PROJECT_DIR}:"
echo ""
echo "Main files:"
echo "  - setup_debian13.sh      (main entry point)"
echo "  - compile.sh             (compiler script)"
echo "  - README.md              (documentation)"
echo ""
echo "Library files (lib/):"
echo "  - lib/config.sh          (configuration)"
echo "  - lib/logging.sh         (logging system)"
echo "  - lib/utils.sh           (utilities)"
echo ""
echo "Module files (modules/):"
echo "  - modules/system.sh      (system configuration)"
echo "  - modules/users.sh       (user management)"
echo "  - modules/docker.sh      (docker setup)"
echo "  - modules/security.sh    (security: ssh, firewall, fail2ban)"
echo "  - modules/monitoring.sh  (monitoring: clamav, rkhunter)"
echo "  - modules/checks.sh      (system checks)"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "All file contents have been provided in the previous artifacts."
echo "Copy each file content to its corresponding location."
echo ""
echo "After creating all files, you can:"
echo "  1. Run directly: ./setup_debian13.sh"
echo "  2. Compile: ./compile.sh"
echo "  3. Distribute: setup_debian13_compiled.sh"
echo ""
echo "═══════════════════════════════════════════════════════════════"