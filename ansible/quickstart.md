# 🚀 Guía de Inicio Rápido - Ansible Playbook Debian 13

## 📦 Paso 1: Crear la Estructura de Archivos

Ejecuta estos comandos para crear toda la estructura necesaria:

```bash
# Crear directorio principal
mkdir -p debian13-vps-ansible
cd debian13-vps-ansible

# Crear estructura de directorios
mkdir -p {inventory,vars,handlers,roles}
mkdir -p roles/{preflight,system,security_baseline,users,ssh,firewall,fail2ban,geoip,docker,docker_deploy,security_tools,maintenance,documentation,validation}/{tasks,templates,handlers,files}

# Crear archivos necesarios
touch site.yml ansible.cfg README.md
touch inventory/hosts
touch vars/{main.yml,users.yml,security.yml}
touch handlers/main.yml
touch run-playbook.sh

# Hacer ejecutable el script helper
chmod +x run-playbook.sh

# Crear .gitignore
cat > .gitignore << 'EOF'
*.retry
.vault_pass
ansible.log
retry/
*.pyc
__pycache__/
.ansible/
vars/vault.yml
EOF
```

## 📝 Paso 2: Copiar el Contenido de los Archivos

Copia el contenido de cada archivo proporcionado en los artifacts:

### Archivos Principales

1. **site.yml** - Playbook principal
2. **ansible.cfg** - Configuración de Ansible
3. **inventory/hosts** - Tu inventario de servidores
4. **run-playbook.sh** - Script helper para ejecutar el playbook

### Variables (carpeta vars/)

1. **vars/main.yml** - Variables principales del sistema
2. **vars/users.yml** - Configuración de usuarios
3. **vars/security.yml** - Parámetros de seguridad

### Handlers

1. **handlers/main.yml** - Handlers globales para servicios

### Roles

Cada rol debe tener su `tasks/main.yml`:

#### roles/preflight/tasks/main.yml
```yaml
---
# Pre-flight checks and backup
[contenido del artifact ansible_role_preflight]
```

#### roles/system/tasks/main.yml
```yaml
---
# System configuration
[contenido del artifact ansible_role_system]
```

#### roles/users/tasks/main.yml
```yaml
---
# User management
[contenido del artifact ansible_role_users]
```

#### roles/ssh/tasks/main.yml
```yaml
---
# SSH hardening
[contenido del artifact ansible_role_ssh]
```

#### roles/firewall/tasks/main.yml
```yaml
---
# UFW firewall
[contenido del artifact ansible_role_firewall]
```

#### roles/docker/tasks/main.yml
```yaml
---
# Docker installation
[contenido del artifact ansible_role_docker]
```

### Templates

#### roles/users/templates/sudoers.j2
```jinja2
[contenido del artifact ansible_template_sudoers]
```

#### roles/docker_deploy/templates/docker-deploy.sh.j2
```bash
[contenido del artifact ansible_template_docker_deploy]
```

#### roles/fail2ban/templates/jail.local.j2
```jinja2
[contenido del artifact ansible_template_fail2ban]
```

## 🔐 Paso 3: Configurar Contraseñas con Vault

```bash
# Crear vault para contraseñas
ansible-vault create vars/vault.yml
```

Contenido del vault:
```yaml
---
# Contraseñas de usuarios (encriptadas por Vault)
vault_administrator_password: "TuPasswordSegura123!"
vault_deployer_password: "OtraPasswordSegura456!"
vault_tuuser_password: "TercerPasswordSegura789!"
```

## ⚙️ Paso 4: Configurar tu Inventario

Edita `inventory/hosts` con los datos de tu servidor:

```ini
[vps_servers]
mi-vps ansible_host=TU_IP_AQUI ansible_user=root ansible_port=22

[vps_servers:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_become=yes
```

## 🎯 Paso 5: Personalizar Variables

### Editar vars/main.yml

Ajusta según tus necesidades:
- Puerto SSH
- Timezone
- Tamaño del swap
- Puertos del firewall

### Editar vars/users.yml

Configura tus usuarios:
- Nombres de usuario
- Grupos
- URLs de SSH keys

### Editar vars/security.yml

Configura parámetros de seguridad:
- Países bloqueados
- Configuración de Fail2ban
- Parámetros de kernel

## 🧪 Paso 6: Probar con Dry-Run

```bash
# Opción 1: Usar el script helper (recomendado)
./run-playbook.sh
# Selecciona opción 2 (Dry-run only)

# Opción 2: Comando directo
ansible-playbook -i inventory/hosts site.yml --check --diff --ask-vault-pass
```

## ▶️ Paso 7: Ejecutar el Playbook

```bash
# Opción 1: Usar el script helper (recomendado)
./run-playbook.sh
# Selecciona opción 1 (Full setup)

# Opción 2: Comando directo
ansible-playbook -i inventory/hosts site.yml --ask-vault-pass
```

## ✅ Paso 8: Verificar la Instalación

```bash
# Verificar en el servidor
ssh -p 2222 usuario@tu-servidor

# Verificar servicios
sudo systemctl status ssh docker fail2ban ufw endlessh

# Ver documentación generada
cat /root/SETUP_INFO.txt
```

## 🔧 Comandos Útiles Adicionales

### Ejecutar solo partes específicas

```bash
# Solo SSH
ansible-playbook -i inventory/hosts site.yml --tags "ssh" --ask-vault-pass

# Solo Docker
ansible-playbook -i inventory/hosts site.yml --tags "docker" --ask-vault-pass

# Solo usuarios
ansible-playbook -i inventory/hosts site.yml --tags "users" --ask-vault-pass
```

### Ver todos los tags disponibles

```bash
ansible-playbook -i inventory/hosts site.yml --list-tags
```

### Ejecutar en modo verbose

```bash
ansible-playbook -i inventory/hosts site.yml --ask-vault-pass -vvv
```

## 📋 Checklist de Instalación

- [ ] Estructura de directorios creada
- [ ] Todos los archivos copiados
- [ ] Variables personalizadas (vars/*.yml)
- [ ] Vault configurado con contraseñas
- [ ] Inventario configurado con tu servidor
- [ ] Dry-run ejecutado y revisado
- [ ] Playbook ejecutado exitosamente
- [ ] SSH probado en el nuevo puerto
- [ ] Servicios verificados en el servidor
- [ ] Documentación revisada (/root/SETUP_INFO.txt)

## 🆘 Solución de Problemas

### No puedo conectar después de cambiar SSH

```bash
# Usar consola del proveedor para acceder y revertir:
sudo sed -i 's/^Port 2222/Port 22/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### Error al ejecutar el vault

```bash
# Verificar el archivo existe
ls -la vars/vault.yml

# Probar a ver el contenido
ansible-vault view vars/vault.yml
```

### Ansible no encuentra el inventario

```bash
# Verificar path en ansible.cfg
grep inventory ansible.cfg

# O especificar manualmente
ansible-playbook -i inventory/hosts site.yml
```

## 📚 Documentación Adicional

- README completo: Ver artifact `ansible_readme`
- Documentación Ansible: https://docs.ansible.com/
- Security Best Practices: https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html

## 🎉 ¡Listo!

Tu servidor Debian 13 ahora está:
- ✅ Configurado y endurecido
- ✅ Con Docker instalado
- ✅ Firewall activo
- ✅ Fail2ban protegiendo SSH
- ✅ Usuarios configurados
- ✅ Antivirus y detección de rootkits
- ✅ SSH tarpit en puerto 22

---

**Siguiente paso**: Despliega tus aplicaciones Docker en `/opt/docker-projects/` usando los helpers `dp` y `dm`.
