# Debian 13 VPS Setup & Hardening - Ansible Playbook

Ansible playbook equivalente al script bash `setup_debian13.sh` para automatizar la configuración y hardening de servidores VPS con Debian 13.

## 📁 Estructura del Proyecto

```
debian13-vps-ansible/
├── site.yml                      # Playbook principal
├── ansible.cfg                   # Configuración de Ansible
├── requirements.yml              # Colecciones Ansible requeridas
├── Makefile                      # Comandos helper
├── run-playbook.sh              # Script interactivo
│
├── inventory/
│   └── hosts                     # Inventario de servidores
│
├── vars/
│   ├── main.yml                  # Variables principales
│   ├── users.yml                 # Configuración de usuarios
│   ├── security.yml              # Configuración de seguridad
│   └── vault.yml                 # Contraseñas encriptadas (crear con vault)
│
└── roles/
    ├── preflight/                # Verificaciones previas y backup
    │   ├── tasks/main.yml
    │   └── templates/backup_manifest.j2
    │
    ├── system/                   # Configuración del sistema
    │   ├── tasks/main.yml
    │   ├── handlers/main.yml
    │   └── defaults/main.yml
    │
    ├── security_baseline/        # Hardening básico
    │   ├── tasks/main.yml
    │   ├── handlers/main.yml
    │   └── templates/
    │       ├── 99-hardening.conf.j2
    │       └── hardening.rules.j2
    │
    ├── users/                    # Gestión de usuarios
    │   ├── tasks/main.yml
    │   └── templates/sudoers.j2
    │
    ├── ssh/                      # Configuración SSH
    │   ├── tasks/main.yml
    │   └── handlers/main.yml
    │
    ├── firewall/                 # Firewall UFW
    │   ├── tasks/main.yml
    │   └── handlers/main.yml
    │
    ├── fail2ban/                 # Fail2ban
    │   ├── tasks/main.yml
    │   ├── handlers/main.yml
    │   └── templates/jail.local.j2
    │
    ├── geoip/                    # Geo-blocking
    │   ├── tasks/main.yml
    │   └── templates/geoip-action.conf.j2
    │
    ├── docker/                   # Instalación Docker
    │   ├── tasks/main.yml
    │   └── handlers/main.yml
    │
    ├── docker_deploy/            # Docker deployment setup
    │   ├── tasks/main.yml
    │   └── templates/
    │       ├── docker-deploy.sh.j2
    │       ├── docker-manage.sh.j2
    │       └── docker-readme.md.j2
    │
    ├── security_tools/           # ClamAV, Rkhunter, Endlessh
    │   ├── tasks/
    │   │   ├── main.yml
    │   │   ├── clamav.yml
    │   │   ├── rkhunter.yml
    │   │   └── endlessh.yml
    │   ├── handlers/main.yml
    │   └── templates/
    │       ├── clamscan-daily.sh.j2
    │       ├── rkhunter-weekly.sh.j2
    │       └── endlessh.conf.j2
    │
    ├── maintenance/              # Updates y mantenimiento
    │   ├── tasks/main.yml
    │   └── templates/50unattended-upgrades.j2
    │
    ├── documentation/            # Generación de docs
    │   ├── tasks/main.yml
    │   └── templates/SETUP_INFO.txt.j2
    │
    └── validation/               # Validación final
        └── tasks/security_check.yml
```

## 🚀 Inicio Rápido

### 1. Prerequisitos

```bash
# Instalar Ansible (Ubuntu/Debian)
sudo apt update
sudo apt install -y ansible

# O con pip
pip3 install ansible

# Verificar instalación
ansible --version
```

### 2. Configurar el Proyecto

```bash
# Crear estructura automáticamente
bash setup-ansible-structure.sh

# Entrar al directorio
cd debian13-vps-ansible
```

### 3. Configurar Inventario

Editar `inventory/hosts` con tus servidores:

```ini
[vps_servers]
mi-vps ansible_host=192.168.1.100 ansible_user=root ansible_port=22

[vps_servers:vars]
ansible_python_interpreter=/usr/bin/python3
```

### 4. Configurar Variables

Editar las variables en `vars/`:

- `vars/main.yml` - Configuración general
- `vars/users.yml` - Usuarios y SSH keys
- `vars/security.yml` - Parámetros de seguridad

### 5. Proteger Contraseñas (Ansible Vault)

```bash
# Crear archivo vault para contraseñas
ansible-vault create vars/vault.yml

# Contenido de ejemplo:
vault_administrator_password: "TuPasswordSegura123"
vault_deployer_password: "OtraPasswordSegura456"
vault_tuuser_password: "PasswordSegura789"
```

### 6. Instalar Dependencias

```bash
# Instalar colecciones requeridas
make install
# O manualmente:
ansible-galaxy collection install -r requirements.yml
```

### 7. Ejecutar el Playbook

```bash
# Opción 1: Script interactivo (recomendado)
./run-playbook.sh

# Opción 2: Con Makefile
make check              # Dry-run
make run                # Ejecución completa

# Opción 3: Comando directo
ansible-playbook -i inventory/hosts site.yml --check --diff --ask-vault-pass  # Dry-run
ansible-playbook -i inventory/hosts site.yml --ask-vault-pass                 # Ejecutar
```

## 🎯 Tags Disponibles

Puedes ejecutar solo partes específicas usando tags:

| Tag | Descripción |
|-----|-------------|
| `preflight` | Verificaciones previas y backup |
| `system` | Configuración del sistema (timezone, locale, swap) |
| `security` | Todas las tareas de seguridad |
| `users` | Creación de usuarios y sudo |
| `ssh` | Configuración y hardening de SSH |
| `firewall` | Configuración de UFW |
| `fail2ban` | Instalación y configuración de Fail2ban |
| `geoip` | Geo-blocking |
| `docker` | Instalación y configuración de Docker |
| `clamav` | Antivirus ClamAV |
| `rkhunter` | Detección de rootkits |
| `endlessh` | SSH tarpit |
| `documentation` | Generación de documentación |
| `validation` | Validación final |

### Ejemplos de Uso con Tags

```bash
# Solo configurar SSH y firewall
make run TAGS=ssh,firewall

# Solo instalar Docker
make run TAGS=docker

# Todo excepto Docker
ansible-playbook -i inventory/hosts site.yml --skip-tags "docker"

# Solo tareas de seguridad
make run TAGS=security
```

## 📋 Configuración Personalizada

### Cambiar Puerto SSH

Editar `vars/main.yml`:

```yaml
ssh_port: 2222  # Cambiar al puerto deseado
```

### Añadir Usuarios

Editar `vars/users.yml`:

```yaml
system_users:
  - name: nuevo_usuario
    password: "{{ vault_nuevo_password }}"
    groups:
      - "{{ docker_deploy_group }}"
    ssh_key_url: "https://github.com/usuario.keys"
    shell: /bin/bash
```

### Configurar Puertos del Firewall

Editar `vars/main.yml`:

```yaml
firewall_allowed_ports:
  - "{{ ssh_port }}/tcp"
  - "80/tcp"
  - "443/tcp"
  - "8080/tcp"  # Añadir puertos adicionales
```

## 🔐 Gestión de Contraseñas con Vault

### Crear Vault

```bash
ansible-vault create vars/vault.yml
```

### Editar Vault

```bash
ansible-vault edit vars/vault.yml
```

### Ver Vault

```bash
ansible-vault view vars/vault.yml
```

### Usar Archivo de Contraseña

```bash
# Crear archivo con la contraseña
echo "mi_password_vault" > .vault_pass
chmod 600 .vault_pass

# ansible.cfg ya está configurado para usarlo
# O especificar manualmente:
ansible-playbook -i inventory/hosts site.yml --vault-password-file .vault_pass
```

## 🔧 Comandos con Makefile

```bash
make help           # Mostrar ayuda
make install        # Instalar dependencias
make check          # Dry-run
make run            # Ejecutar playbook completo
make run TAGS=ssh   # Ejecutar con tags específicos
make run LIMIT=vps1 # Ejecutar solo en vps1
make inventory      # Ver inventario y probar conexión
make vault-create   # Crear vault
make vault-edit     # Editar vault
make validate       # Solo validación
make clean          # Limpiar logs y retry files

# Shortcuts
make ssh            # Solo configurar SSH
make firewall       # Solo configurar firewall
make docker         # Solo instalar Docker
make users          # Solo gestionar usuarios
make security       # Solo tareas de seguridad
```

## 📊 Verificación Post-Instalación

### Verificar Estado del Sistema

```bash
# Con el playbook
make validate

# Manualmente en el servidor
ssh -p 2222 usuario@servidor

# Verificar servicios
sudo systemctl status ssh docker fail2ban ufw endlessh

# Ver documentación generada
cat /root/SETUP_INFO.txt
```

## ⚠️ Notas Importantes

1. **Probar SSH**: Después de cambiar el puerto SSH, prueba la conexión desde otra terminal antes de cerrar la sesión actual.

2. **Contraseñas**: SIEMPRE usa Ansible Vault para las contraseñas en producción.

3. **Backup**: El playbook crea backups automáticos en `/root/config_backup_*`.

4. **Dry-run**: Usa siempre `make check` primero para ver qué cambiará.

5. **Idempotencia**: El playbook es idempotente - puedes ejecutarlo múltiples veces sin problemas.

## 🐛 Troubleshooting

### No se puede conectar después de cambiar SSH

```bash
# Conectar con puerto antiguo si aún está activo
ssh -p 22 root@servidor

# O usar consola del proveedor VPS para revertir cambios
```

### Error de Vault

```bash
# Verificar que usas la contraseña correcta
ansible-vault view vars/vault.yml
```

### Servicios no inician

```bash
# Verificar logs
ansible -i inventory/hosts vps_servers -m shell -a "journalctl -xe"
```

## 📚 Referencias

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)

## 📝 Licencia

Este playbook está basado en el script `setup_debian13.sh` por Rodrigo Sampedro Casis.

---

**Autor**: Conversión a Ansible  
**Versión**: 1.1  
**Fecha**: 2025-12-31