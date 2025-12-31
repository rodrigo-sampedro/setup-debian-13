#!/usr/bin/env bash
# setup-ansible-structure.sh
# Creates complete Ansible playbook structure for Debian 13 VPS setup

set -e

PROJECT_NAME="debian13-vps-ansible"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║     Debian 13 VPS Ansible - Structure Setup Script               ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Check if project directory exists
if [ -d "$PROJECT_NAME" ]; then
    echo "⚠️  Directory $PROJECT_NAME already exists!"
    read -p "Do you want to continue and overwrite? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo "📁 Creating project directory: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo "📁 Creating directory structure..."

# Main directories
mkdir -p {inventory,vars,handlers,group_vars,host_vars}

# Roles
ROLES=(
    "preflight"
    "system"
    "security_baseline"
    "users"
    "ssh"
    "firewall"
    "fail2ban"
    "geoip"
    "docker"
    "docker_deploy"
    "security_tools"
    "maintenance"
    "documentation"
    "validation"
)

for role in "${ROLES[@]}"; do
    mkdir -p "roles/$role"/{tasks,templates,handlers,files,defaults,vars}
    touch "roles/$role/tasks/main.yml"
done

# Additional task files for security_tools
touch roles/security_tools/tasks/{clamav.yml,rkhunter.yml,endlessh.yml}
touch roles/validation/tasks/security_check.yml

echo "📝 Creating base files..."

# Create main files
touch {site.yml,ansible.cfg,README.md,Makefile,requirements.yml}
touch inventory/hosts
touch vars/{main.yml,users.yml,security.yml}
touch handlers/main.yml
touch run-playbook.sh

# Make scripts executable
chmod +x run-playbook.sh

# Create .gitignore
cat > .gitignore << 'EOF'
*.retry
.vault_pass
ansible.log
retry/
*.pyc
__pycache__/
.ansible/
vars/vault.yml
.DS_Store
*.swp
*.swo
*~
EOF

# Create example vault password file
cat > .vault_pass.example << 'EOF'
# Rename this file to .vault_pass and add your vault password
# chmod 600 .vault_pass
your_vault_password_here
EOF

echo "📋 Creating file list..."

# Create a file list for reference
cat > FILE_LIST.md << 'EOF'
# File Structure

## Main Files
- site.yml                      # Main playbook
- ansible.cfg                   # Ansible configuration
- requirements.yml              # Galaxy collections
- Makefile                      # Helper commands
- run-playbook.sh              # Interactive runner script
- README.md                    # Documentation

## Configuration
- inventory/hosts              # Server inventory
- vars/main.yml               # Main variables
- vars/users.yml              # User configuration
- vars/security.yml           # Security settings
- vars/vault.yml              # Encrypted passwords (create with ansible-vault)
- handlers/main.yml           # Global handlers

## Roles

### preflight
- roles/preflight/tasks/main.yml
- roles/preflight/templates/backup_manifest.j2

### system
- roles/system/tasks/main.yml

### security_baseline
- roles/security_baseline/tasks/main.yml
- roles/security_baseline/templates/99-hardening.conf.j2
- roles/security_baseline/templates/hardening.rules.j2

### users
- roles/users/tasks/main.yml
- roles/users/templates/sudoers.j2

### ssh
- roles/ssh/tasks/main.yml

### firewall
- roles/firewall/tasks/main.yml

### fail2ban
- roles/fail2ban/tasks/main.yml
- roles/fail2ban/templates/jail.local.j2

### geoip
- roles/geoip/tasks/main.yml
- roles/geoip/templates/geoip-action.conf.j2

### docker
- roles/docker/tasks/main.yml

### docker_deploy
- roles/docker_deploy/tasks/main.yml
- roles/docker_deploy/templates/docker-deploy.sh.j2
- roles/docker_deploy/templates/docker-manage.sh.j2
- roles/docker_deploy/templates/docker-readme.md.j2

### security_tools
- roles/security_tools/tasks/main.yml
- roles/security_tools/tasks/clamav.yml
- roles/security_tools/tasks/rkhunter.yml
- roles/security_tools/tasks/endlessh.yml
- roles/security_tools/templates/clamscan-daily.sh.j2
- roles/security_tools/templates/rkhunter-weekly.sh.j2
- roles/security_tools/templates/endlessh.conf.j2

### maintenance
- roles/maintenance/tasks/main.yml
- roles/maintenance/templates/50unattended-upgrades.j2

### documentation
- roles/documentation/tasks/main.yml
- roles/documentation/templates/SETUP_INFO.txt.j2

### validation
- roles/validation/tasks/security_check.yml
EOF

echo "✅ Directory structure created successfully!"
echo ""
echo "📍 Project location: $(pwd)"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. Copy content from artifacts to respective files (see FILE_LIST.md)"
echo "  3. Edit inventory/hosts with your server details"
echo "  4. Customize vars/*.yml files"
echo "  5. Create vault: ansible-vault create vars/vault.yml"
echo "  6. Install requirements: make install"
echo "  7. Run: make check (dry-run) or make run"
echo ""
echo "For detailed instructions, see the README.md and Quick Start Guide."
echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    Structure Created Successfully!                ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
