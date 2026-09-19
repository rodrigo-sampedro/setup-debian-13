#!/usr/bin/env bash
# run-playbook.sh
# Helper script to run the Debian 13 VPS setup playbook

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}           Debian 13 VPS Setup - Ansible Runner                   ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_menu() {
    echo -e "${GREEN}Available Options:${NC}"
    echo ""
    echo "  1) 🚀 Full setup (dry-run first, then execute)"
    echo "  2) 🧪 Dry-run only (check mode)"
    echo "  3) ▶️  Execute without dry-run"
    echo "  4) 🎯 Execute with specific tags"
    echo "  5) 📋 List all available tags"
    echo "  6) 🔍 Check inventory"
    echo "  7) 🔐 Create/edit vault"
    echo "  8) 📊 Run validation only"
    echo "  0) 🚪 Exit"
    echo ""
}

check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}Error: ansible-playbook not found. Please install Ansible.${NC}"
        exit 1
    fi
    
    if [ ! -f "site.yml" ]; then
        echo -e "${RED}Error: site.yml not found. Run this script from the project root.${NC}"
        exit 1
    fi
    
    if [ ! -f "inventory/hosts" ]; then
        echo -e "${RED}Error: inventory/hosts not found.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All requirements met${NC}"
    echo ""
}

dry_run() {
    echo -e "${YELLOW}Running dry-run (check mode)...${NC}"
    ansible-playbook -i inventory/hosts site.yml --check --diff --ask-vault-pass
}

execute_playbook() {
    echo -e "${YELLOW}Executing playbook...${NC}"
    ansible-playbook -i inventory/hosts site.yml --ask-vault-pass
}

execute_with_tags() {
    echo -e "${YELLOW}Enter tags (comma-separated, e.g., ssh,firewall):${NC}"
    read -r tags
    
    if [ -z "$tags" ]; then
        echo -e "${RED}No tags provided. Aborting.${NC}"
        return
    fi
    
    echo -e "${YELLOW}Executing with tags: $tags${NC}"
    ansible-playbook -i inventory/hosts site.yml --tags "$tags" --ask-vault-pass
}

list_tags() {
    echo -e "${YELLOW}Available tags:${NC}"
    echo ""
    ansible-playbook -i inventory/hosts site.yml --list-tags 2>/dev/null | grep "TASK TAGS:" -A 100
    echo ""
}

check_inventory() {
    echo -e "${YELLOW}Inventory hosts:${NC}"
    echo ""
    ansible-inventory -i inventory/hosts --list
    echo ""
    
    echo -e "${YELLOW}Testing connection...${NC}"
    ansible -i inventory/hosts all -m ping
    echo ""
}

manage_vault() {
    echo -e "${GREEN}Vault Management:${NC}"
    echo "  1) Create new vault"
    echo "  2) Edit existing vault"
    echo "  3) View vault"
    echo "  4) Change vault password"
    echo "  0) Back"
    echo ""
    read -rp "Select option: " vault_option
    
    case $vault_option in
        1)
            ansible-vault create vars/vault.yml
            ;;
        2)
            ansible-vault edit vars/vault.yml
            ;;
        3)
            ansible-vault view vars/vault.yml
            ;;
        4)
            ansible-vault rekey vars/vault.yml
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

run_validation() {
    echo -e "${YELLOW}Running validation checks...${NC}"
    ansible-playbook -i inventory/hosts site.yml --tags "validation" --ask-vault-pass
}

full_setup() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}STEP 1/2: DRY-RUN${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    dry_run
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Dry-run completed. Review the changes above.${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -rp "Do you want to proceed with the actual execution? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}STEP 2/2: EXECUTION${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
        echo ""
        execute_playbook
    else
        echo -e "${YELLOW}Execution cancelled.${NC}"
    fi
}

# Main
main() {
    print_header
    check_requirements
    
    while true; do
        print_menu
        read -rp "Select an option [0-8]: " choice
        echo ""
        
        case $choice in
            1)
                full_setup
                ;;
            2)
                dry_run
                ;;
            3)
                execute_playbook
                ;;
            4)
                execute_with_tags
                ;;
            5)
                list_tags
                ;;
            6)
                check_inventory
                ;;
            7)
                manage_vault
                ;;
            8)
                run_validation
                ;;
            0)
                echo -e "${GREEN}Exiting. Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac
        
        echo ""
        read -rp "Press Enter to continue..."
        clear
        print_header
    done
}

# Run
main
