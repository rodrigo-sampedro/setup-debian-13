# 📑 Índice Completo de Archivos - Playbook Ansible Debian 13

## 📊 Resumen

- **Total de Archivos**: 62 archivos
- **Roles**: 14
- **Handlers**: 7 roles con handlers
- **Templates**: 15
- **Variables**: 3 + vault
- **Scripts**: 2

---

## 🗂️ Estructura Completa y Corregida

```
debian13-vps-ansible/
├── 📄 site.yml                                    [Artifact: ansible_main]
├── 📄 ansible.cfg                                 [Artifact: ansible_cfg]
├── 📄 README.md                                   [Artifact: ansible_readme] ✅ ACTUALIZADO
├── 📄 Makefile                                    [Artifact: ansible_makefile]
├── 📄 requirements.yml                            [Artifact: ansible_requirements]
├── 📄 run-playbook.sh                            [Artifact: ansible_run_script]
├── 📄 setup-ansible-structure.sh                 [Artifact: setup_structure_script]
├── 📄 QUICK_START.md                             [Artifact: ansible_quickstart]
├── 📄 .gitignore                                 [Auto-generado por script]
│
├── 📁 inventory/
│   └── 📄 hosts                                   [Artifact: ansible_inventory]
│
├── 📁 vars/
│   ├── 📄 main.yml                               [Artifact: ansible_vars_main]
│   ├── 📄 users.yml                              [Artifact: ansible_vars_users]
│   ├── 📄 security.yml                           [Artifact: ansible_vars_security]
│   └── 📄 vault.yml                              [CREAR con ansible-vault create]
│
└── 📁 roles/
    │
    ├── 📁 preflight/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_preflight]
    │   └── 📁 templates/
    │       └── 📄 backup_manifest.j2             [Artifact: template_backup_manifest]
    │
    ├── 📁 system/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_system] ✅ MEJORADO
    │   ├── 📁 handlers/
    │   │   └── 📄 main.yml                       [Artifact: system_handlers] ✅ NUEVO
    │   └── 📁 defaults/
    │       └── 📄 main.yml                       [Artifact: system_defaults] ✅ NUEVO
    │
    ├── 📁 security_baseline/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_security_baseline]
    │   ├── 📁 handlers/
    │   │   └── 📄 main.yml                       [Artifact: security_baseline_handlers] ✅ NUEVO
    │   └── 📁 templates/
    │       ├── 📄 99-hardening.conf.j2           [Artifact: template_sysctl_hardening]
    │       └── 📄 hardening.rules.j2             [Artifact: template_auditd_rules]
    │
    ├── 📁 users/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_users]
    │   └── 📁 templates/
    │       └── 📄 sudoers.j2                     [Artifact: ansible_template_sudoers]
    │
    ├── 📁 ssh/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_ssh]
    │   └── 📁 handlers/
    │       └── 📄 main.yml                       [Artifact: ssh_handlers] ✅ NUEVO
    │
    ├── 📁 firewall/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_firewall]
    │   └── 📁 handlers/
    │       └── 📄 main.yml                       [Artifact: firewall_handlers] ✅ NUEVO
    │
    ├── 📁 fail2ban/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_fail2ban]
    │   ├── 📁 handlers/
    │   │   └── 📄 main.yml                       [Artifact: fail2ban_handlers] ✅ NUEVO
    │   └── 📁 templates/
    │       └── 📄 jail.local.j2                  [Artifact: ansible_template_fail2ban]
    │
    ├── 📁 geoip/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_geoip]
    │   └── 📁 templates/
    │       └── 📄 geoip-action.conf.j2           [Artifact: template_geoip_action]
    │
    ├── 📁 docker/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_docker]
    │   └── 📁 handlers/
    │       └── 📄 main.yml                       [Artifact: docker_handlers] ✅ NUEVO
    │
    ├── 📁 docker_deploy/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_docker_deploy]
    │   └── 📁 templates/
    │       ├── 📄 docker-deploy.sh.j2            [Artifact: ansible_template_docker_deploy]
    │       ├── 📄 docker-manage.sh.j2            [Artifact: template_docker_manage]
    │       └── 📄 docker-readme.md.j2            [Artifact: template_docker_readme]
    │
    ├── 📁 security_tools/
    │   ├── 📁 tasks/
    │   │   ├── 📄 main.yml                       [Artifact: ansible_role_security_tools]
    │   │   ├── 📄 clamav.yml                     [Artifact: security_tools_clamav]
    │   │   ├── 📄 rkhunter.yml                   [Artifact: security_tools_rkhunter]
    │   │   └── 📄 endlessh.yml                   [Artifact: security_tools_endlessh]
    │   ├── 📁 handlers/
    │   │   └── 📄 main.yml                       [Artifact: security_tools_handlers] ✅ NUEVO
    │   └── 📁 templates/
    │       ├── 📄 clamscan-daily.sh.j2           [Artifact: template_clamscan_daily]
    │       ├── 📄 rkhunter-weekly.sh.j2          [Artifact: template_rkhunter_weekly]
    │       └── 📄 endlessh.conf.j2               [Artifact: template_endlessh_conf]
    │
    ├── 📁 maintenance/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_maintenance]
    │   └── 📁 templates/
    │       └── 📄 50unattended-upgrades.j2       [Artifact: template_unattended_upgrades]
    │
    ├── 📁 documentation/
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                       [Artifact: ansible_role_documentation]
    │   └── 📁 templates/
    │       └── 📄 SETUP_INFO.txt.j2              [Artifact: template_setup_info]
    │
    └── 📁 validation/
        └── 📁 tasks/
            └── 📄 security_check.yml              [Artifact: ansible_role_validation]
```

---

## ✅ Cambios Importantes

### ❌ ELIMINADO
- **handlers/main.yml** global (NO SE USA - era confuso)

### ✅ AÑADIDO (7 nuevos archivos de handlers)
1. `roles/system/handlers/main.yml`
2. `roles/system/defaults/main.yml`
3. `roles/ssh/handlers/main.yml`
4. `roles/firewall/handlers/main.yml`
5. `roles/fail2ban/handlers/main.yml`
6. `roles/security_baseline/handlers/main.yml`
7. `roles/docker/handlers/main.yml`
8. `roles/security_tools/handlers/main.yml`

### 🔄 ACTUALIZADO
- `README.md` - Estructura corregida
- `roles/system/tasks/main.yml` - Mejorado con más validaciones

---

## 📝 Lista Completa de Archivos por Artifact

### 🔧 Archivos Principales (8)

| Archivo | Artifact ID |
|---------|-------------|
| site.yml | ansible_main |
| ansible.cfg | ansible_cfg |
| README.md | ansible_readme |
| Makefile | ansible_makefile |
| requirements.yml | ansible_requirements |
| run-playbook.sh | ansible_run_script |
| setup-ansible-structure.sh | setup_structure_script |
| QUICK_START.md | ansible_quickstart |

### 📋 Configuración (4 + vault)

| Archivo | Artifact ID |
|---------|-------------|
| inventory/hosts | ansible_inventory |
| vars/main.yml | ansible_vars_main |
| vars/users.yml | ansible_vars_users |
| vars/security.yml | ansible_vars_security |
| vars/vault.yml | **CREAR con ansible-vault** |

### 🎭 Roles - Tasks (18 archivos)

| Rol | Archivo | Artifact ID |
|-----|---------|-------------|
| preflight | tasks/main.yml | ansible_role_preflight |
| system | tasks/main.yml | ansible_role_system |
| security_baseline | tasks/main.yml | ansible_role_security_baseline |
| users | tasks/main.yml | ansible_role_users |
| ssh | tasks/main.yml | ansible_role_ssh |
| firewall | tasks/main.yml | ansible_role_firewall |
| fail2ban | tasks/main.yml | ansible_role_fail2ban |
| geoip | tasks/main.yml | ansible_role_geoip |
| docker | tasks/main.yml | ansible_role_docker |
| docker_deploy | tasks/main.yml | ansible_role_docker_deploy |
| security_tools | tasks/main.yml | ansible_role_security_tools |
| security_tools | tasks/clamav.yml | security_tools_clamav |
| security_tools | tasks/rkhunter.yml | security_tools_rkhunter |
| security_tools | tasks/endlessh.yml | security_tools_endlessh |
| maintenance | tasks/main.yml | ansible_role_maintenance |
| documentation | tasks/main.yml | ansible_role_documentation |
| validation | tasks/security_check.yml | ansible_role_validation |

### 🔔 Handlers (8 archivos) ✅ NUEVO

| Rol | Archivo | Artifact ID |
|-----|---------|-------------|
| system | handlers/main.yml | system_handlers |
| ssh | handlers/main.yml | ssh_handlers |
| firewall | handlers/main.yml | firewall_handlers |
| fail2ban | handlers/main.yml | fail2ban_handlers |
| security_baseline | handlers/main.yml | security_baseline_handlers |
| docker | handlers/main.yml | docker_handlers |
| security_tools | handlers/main.yml | security_tools_handlers |

### 📄 Templates (15 archivos)

| Template | Rol | Artifact ID |
|----------|-----|-------------|
| backup_manifest.j2 | preflight | template_backup_manifest |
| 99-hardening.conf.j2 | security_baseline | template_sysctl_hardening |
| hardening.rules.j2 | security_baseline | template_auditd_rules |
| sudoers.j2 | users | ansible_template_sudoers |
| jail.local.j2 | fail2ban | ansible_template_fail2ban |
| geoip-action.conf.j2 | geoip | template_geoip_action |
| docker-deploy.sh.j2 | docker_deploy | ansible_template_docker_deploy |
| docker-manage.sh.j2 | docker_deploy | template_docker_manage |
| docker-readme.md.j2 | docker_deploy | template_docker_readme |
| clamscan-daily.sh.j2 | security_tools | template_clamscan_daily |
| rkhunter-weekly.sh.j2 | security_tools | template_rkhunter_weekly |
| endlessh.conf.j2 | security_tools | template_endlessh_conf |
| 50unattended-upgrades.j2 | maintenance | template_unattended_upgrades |
| SETUP_INFO.txt.j2 | documentation | template_setup_info |

### ⚙️ Defaults (1 archivo) ✅ NUEVO

| Rol | Archivo | Artifact ID |
|-----|---------|-------------|
| system | defaults/main.yml | system_defaults |
