# Makefile
# Helper commands for Ansible playbook management

.PHONY: help install check run tags inventory vault-create vault-edit validate clean

INVENTORY := inventory/hosts
PLAYBOOK := site.yml

help:
	@echo "Debian 13 VPS Setup - Ansible Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  install       - Install Ansible Galaxy requirements"
	@echo "  check         - Run playbook in check mode (dry-run)"
	@echo "  run           - Execute the full playbook"
	@echo "  tags          - List all available tags"
	@echo "  inventory     - Display inventory information"
	@echo "  vault-create  - Create a new vault file"
	@echo "  vault-edit    - Edit the vault file"
	@echo "  validate      - Run validation checks only"
	@echo "  clean         - Remove retry files and logs"
	@echo ""
	@echo "Examples:"
	@echo "  make check              - Dry run"
	@echo "  make run                - Full execution"
	@echo "  make run TAGS=ssh       - Run only SSH tasks"
	@echo "  make run LIMIT=vps1     - Run only on vps1"

install:
	@echo "Installing Ansible Galaxy requirements..."
	ansible-galaxy collection install -r requirements.yml

check:
	@echo "Running playbook in check mode..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check --diff --ask-vault-pass

run:
ifdef TAGS
	@echo "Running playbook with tags: $(TAGS)"
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "$(TAGS)" --ask-vault-pass $(if $(LIMIT),--limit "$(LIMIT)")
else ifdef LIMIT
	@echo "Running playbook limited to: $(LIMIT)"
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --ask-vault-pass --limit "$(LIMIT)"
else
	@echo "Running full playbook..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --ask-vault-pass
endif

tags:
	@echo "Available tags:"
	@ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --list-tags 2>/dev/null | grep "TASK TAGS:" -A 100

inventory:
	@echo "Inventory information:"
	@ansible-inventory -i $(INVENTORY) --list
	@echo ""
	@echo "Testing connectivity..."
	@ansible -i $(INVENTORY) all -m ping

vault-create:
	@echo "Creating new vault file..."
	ansible-vault create vars/vault.yml

vault-edit:
	@echo "Editing vault file..."
	ansible-vault edit vars/vault.yml

vault-view:
	@echo "Viewing vault file..."
	ansible-vault view vars/vault.yml

validate:
	@echo "Running validation checks..."
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "validation" --ask-vault-pass

clean:
	@echo "Cleaning up..."
	rm -f *.retry
	rm -f ansible.log
	rm -rf retry/
	@echo "Clean complete"

# Shortcuts
ssh: TAGS=ssh
ssh: run

firewall: TAGS=firewall
firewall: run

docker: TAGS=docker
docker: run

users: TAGS=users
users: run

security: TAGS=security
security: run
