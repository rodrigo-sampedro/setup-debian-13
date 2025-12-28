# Debian 13 VPS Setup - Versión Modular

Sistema automatizado de configuración y hardening para servidores Debian 13.

## 📁 Estructura del Proyecto

```
setup_debian13/
├── setup_debian13.sh           # Script principal (entry point)
├── compile.sh                  # Compilador para generar versión única
├── lib/                        # Librerías core
│   ├── config.sh              # Configuración global
│   ├── logging.sh             # Sistema de logging
│   └── utils.sh               # Utilidades comunes
├── modules/                    # Módulos funcionales
│   ├── system.sh              # Configuración del sistema (timezone, swap, apt, etc.)
│   ├── users.sh               # Gestión de usuarios y grupos
│   ├── docker.sh              # Instalación y configuración de Docker
│   ├── security.sh            # SSH, firewall, fail2ban, endlessh
│   ├── monitoring.sh          # ClamAV, rkhunter, auditd
│   └── checks.sh              # Funciones de verificación de estado
└── README.md                   # Este archivo
```

## 🚀 Uso Rápido

### Modo Desarrollo (Modular)

```bash
# Clonar o descargar el proyecto
git clone https://tu-repo/setup_debian13.git
cd setup_debian13

# Ejecutar en modo modular
chmod +x setup_debian13.sh
sudo ./setup_debian13.sh
```

### Modo Producción (Compilado)

```bash
# Compilar en un único archivo
chmod +x compile.sh
./compile.sh

# Ejecutar el archivo compilado
sudo ./setup_debian13_compiled.sh
```

### Descarga y Ejecución Directa

```bash
# Descargar y ejecutar (usar versión compilada)
curl -fsSL https://tu-servidor/setup_debian13_compiled.sh | sudo bash
```

## 🔧 Opciones de Línea de Comandos

```bash
./setup_debian13.sh [OPCIONES]

OPCIONES:
  --no-menu    Ejecutar setup automáticamente sin menú interactivo
  --dry-run    Mostrar qué se haría sin realizar cambios
  --help, -h   Mostrar ayuda

EJEMPLOS:
  ./setup_debian13.sh                    # Menú interactivo
  ./setup_debian13.sh --no-menu          # Ejecución automática
  ./setup_debian13.sh --dry-run          # Vista previa de cambios
```

## 📝 Menú Interactivo

```
1) 🚀 Run full setup & hardening       - Ejecutar configuración completa
2) 📊 Check system status              - Verificar estado del sistema
3) 📋 View documentation               - Ver documentación generada
4) 🧪 Dry-run (preview changes)        - Vista previa sin cambios
5) 🔒 Run fortress hardening           - Ejecutar hardening adicional
6) 🗑️  Clear progress & restart        - Limpiar progreso y reiniciar
7) 🔄 Reconfigure services             - Reconfigurar SSH, Fail2ban, UFW
0) 🚪 Exit                             - Salir
```

## ⚙️ Configuración

### Archivo: `lib/config.sh`

Personaliza los valores antes de ejecutar:

```bash
# SSH
SSH_PORT=2222
SSH_ALLOWED_USERS=( "administrator" "deployer" "tuUser" )

# Usuarios (formato: username:password:sshkey_url)
USERS=(
  "administrator:passStrong:"
  "deployer:pass&:"
  "tuUser:pass:"
)

# Firewall
FIREWALL_ALLOWED_PORTS=(
  "${SSH_PORT}/tcp"
  "80/tcp"
  "443/tcp"
)

# Geo-Blocking
BLOCKED_COUNTRIES=("CN" "RU" "KP" "IR" "PK" "BY")

# Docker
DOCKER_DEPLOY_GROUP="docker_deploy"
DOCKER_DEPLOY_BASE_DIR="/opt/docker-projects"

# Sistema
TIMEZONE="Europe/Madrid"
SWAP_SIZE="2G"
```

## 📦 Módulos

### `modules/system.sh`
- Backup de configuraciones
- Timezone y locales
- APT y actualizaciones
- Swap
- Sysctl (kernel hardening)
- Unattended upgrades
- Logrotate

### `modules/users.sh`
- Creación de usuarios
- Configuración de SSH keys
- Políticas sudo
- Grupo docker_deploy

### `modules/docker.sh`
- Instalación de Docker oficial
- Docker Compose
- Configuración del daemon
- Scripts helper (docker-deploy, docker-manage)
- Directorio de proyectos compartidos
- Aliases (dp, dm)

### `modules/security.sh`
- SSH hardening (puerto custom, sin root, solo keys)
- Banner SSH
- UFW firewall
- Fail2ban
- GeoIP blocking
- Endlessh (SSH tarpit en puerto 22)

### `modules/monitoring.sh`
- ClamAV (antivirus con scans diarios)
- Rkhunter (detección de rootkits)
- Chkrootkit
- Auditd
- Fortress script (hardening adicional)
- Documentación del sistema

### `modules/checks.sh`
- Verificación de estado de servicios
- Disk usage
- Memory usage
- Docker status
- Firewall status
- Fail2ban status
- Security services
- SSH logins recientes
- Updates disponibles

## 🔨 Compilación

El script `compile.sh` genera un único archivo ejecutable:

```bash
chmod +x compile.sh
./compile.sh
```

Esto crea `setup_debian13_compiled.sh` que:
- ✅ No requiere estructura de directorios
- ✅ Se puede descargar y ejecutar directamente
- ✅ Contiene todo el código en un solo archivo
- ✅ Es funcionalmente idéntico a la versión modular

### Proceso de Compilación

1. Verifica estructura de directorios
2. Verifica archivos requeridos
3. Extrae contenido sin headers duplicados
4. Combina en orden: config → logging → utils → modules → main
5. Genera script ejecutable único

## 📋 Características Implementadas

### Seguridad
- ✅ SSH en puerto custom (2222)
- ✅ SSH solo con keys (no passwords)
- ✅ Endlessh en puerto 22 (tarpit)
- ✅ UFW firewall configurado
- ✅ Fail2ban activo
- ✅ GeoIP blocking (CN, RU, KP, IR, PK, BY)
- ✅ Kernel hardening (sysctl)
- ✅ Auditd monitoring
- ✅ SSH banner de advertencia

### Monitoreo
- ✅ ClamAV (daily scans 2 AM)
- ✅ Rkhunter + Chkrootkit (weekly, Sunday 3 AM)
- ✅ Unattended security updates
- ✅ Logrotate configurado

### Docker
- ✅ Docker CE + Compose oficial
- ✅ Grupo docker_deploy para colaboración
- ✅ Scripts helper: docker-deploy, docker-manage
- ✅ Aliases: dp, dm
- ✅ Directorio compartido: /opt/docker-projects
- ✅ Daemon configurado (log limits, security)

### Sistema
- ✅ Timezone configurado
- ✅ Locales (en_US, es_ES)
- ✅ Swap de 2GB
- ✅ Full system upgrade
- ✅ Backup de configs originales

## 🎯 Próximos Pasos Después del Setup

1. **Verificar SSH**
   ```bash
   # Desde otro terminal
   ssh -p 2222 usuario@ip_del_servidor
   ```

2. **Hardening Adicional** (opcional)
   ```bash
   cd /root
   ./fortress_improved.sh -l high -n --explain
   # Luego reconfigurar servicios (opción 7 del menú)
   ```

3. **Deploy Docker Projects**
   ```bash
   cd /opt/docker-projects
   # Crear tu docker-compose.yml
   dp start docker-compose.yml
   ```

4. **Monitorear**
   ```bash
   # Ver logs de ClamAV
   tail -f /var/log/clamav/daily-scan.log
   
   # Ver logs de Rkhunter
   tail -f /var/log/rkhunter-weekly.log
   
   # Check Fail2ban
   fail2ban-client status sshd
   ```

## 📊 Comandos Útiles

```bash
# Estado del sistema
dm ps                           # Containers Docker
ufw status verbose              # Firewall
fail2ban-client status sshd     # Fail2ban
systemctl status endlessh       # SSH tarpit
systemctl status clamav-daemon  # Antivirus

# Logs
journalctl -u ssh               # SSH logs
ausearch -k docker              # Audit logs
tail -f /var/log/init_phase1.log # Setup log
```

## ⚠️ Notas Importantes

1. **SIEMPRE** prueba la conexión SSH en el nuevo puerto antes de cerrar tu sesión actual
2. El script crea un backup de configuraciones en `/root/config_backup_*`
3. La documentación completa se genera en `/root/SETUP_INFO.txt`
4. Los logs están en `/var/log/init_phase1.log`
5. El script puede resumirse desde el último paso completado

## 🐛 Troubleshooting

### SSH no conecta en el puerto 2222
```bash
# Verificar que SSH esté escuchando
ss -tlnp | grep 2222

# Verificar firewall
ufw status | grep 2222

# Ver logs
journalctl -u ssh -f
```

### Endlessh no arranca
```bash
# Verificar capabilities
getcap /usr/bin/endlessh

# Debe mostrar: cap_net_bind_service+ep

# Ver logs
journalctl -u endlessh -f
```

### ClamAV no actualiza
```bash
# Verificar servicio
systemctl status clamav-freshclam

# Actualizar manualmente
sudo freshclam
```

## 📄 Licencia

Este proyecto está diseñado para uso interno. Modifica según tus necesidades.

## 👤 Autor

Rodrigo Sampedro Casis - 2025-12-26

---

**Version**: 1.1  
**Última actualización**: 2025-12-27