# Guía Completa de Setup - Debian 13 VPS Modular

## 📦 Resumen del Proyecto

Has recibido una refactorización completa del script monolítico original en una estructura modular profesional con las siguientes ventajas:

- ✅ **Modular**: Código organizado por responsabilidades
- ✅ **Mantenible**: Fácil de actualizar y debuggear
- ✅ **Compilable**: Se puede generar versión única para producción
- ✅ **Documentado**: Comentarios y README completo
- ✅ **Verificable**: Scripts de verificación incluidos

## 🗂️ Estructura Final

```
setup_debian13/
├── setup_debian13.sh           # Script principal (entry point)
├── compile.sh                  # Compilador para versión única
├── README.md                   # Documentación del proyecto
├── lib/                        # Librerías core
│   ├── config.sh              # ⚙️  Configuración global
│   ├── logging.sh             # 📝 Sistema de logging
│   └── utils.sh               # 🔧 Utilidades comunes
└── modules/                    # Módulos funcionales
    ├── system.sh              # 🖥️  Configuración del sistema
    ├── users.sh               # 👤 Gestión de usuarios
    ├── docker.sh              # 🐳 Docker setup
    ├── security.sh            # 🔒 Seguridad (SSH, firewall, etc)
    ├── monitoring.sh          # 📊 Monitoreo (ClamAV, rkhunter)
    └── checks.sh              # ✅ Verificaciones de estado
```

## 🚀 Pasos de Instalación

### Paso 1: Crear la Estructura

Tienes **13 archivos** que copiar según los artefactos proporcionados:

#### Archivos Principales (3)
1. **setup_debian13.sh** - Main entry point
2. **compile.sh** - Compilador
3. **README.md** - Documentación

#### Librería (3 archivos en `lib/`)
4. **lib/config.sh** - Configuración
5. **lib/logging.sh** - Sistema de logging
6. **lib/utils.sh** - Utilidades

#### Módulos (6 archivos en `modules/`)
7. **modules/system.sh** - Sistema
8. **modules/users.sh** - Usuarios
9. **modules/docker.sh** - Docker
10. **modules/security.sh** - Seguridad
11. **modules/monitoring.sh** - Monitoreo
12. **modules/checks.sh** - Verificaciones

#### Utilidades Extra (2 - opcionales)
13. **setup_structure.sh** - Crear estructura
14. **verify_structure.sh** - Verificar estructura

### Paso 2: Crear Estructura de Directorios

```bash
mkdir -p setup_debian13/{lib,modules}
cd setup_debian13
```

### Paso 3: Copiar Cada Archivo

Para cada archivo, copia el contenido del artefacto correspondiente:

```bash
# Ejemplo para setup_debian13.sh
cat > setup_debian13.sh << 'EOF'
[COPIAR CONTENIDO DEL ARTEFACTO "debian_setup_modular"]
EOF

# Ejemplo para lib/config.sh
cat > lib/config.sh << 'EOF'
[COPIAR CONTENIDO DEL ARTEFACTO "lib_config"]
EOF

# Y así sucesivamente...
```

### Paso 4: Establecer Permisos

```bash
# Scripts ejecutables
chmod +x setup_debian13.sh
chmod +x compile.sh

# Si creaste los scripts de utilidad
chmod +x setup_structure.sh 2>/dev/null || true
chmod +x verify_structure.sh 2>/dev/null || true

# Archivos de librería y módulos
chmod 644 lib/*.sh
chmod 644 modules/*.sh
chmod 644 README.md
```

### Paso 5: Verificar Estructura (Opcional)

Si creaste el script `verify_structure.sh`:

```bash
cd ..  # Volver al directorio padre
./setup_debian13/verify_structure.sh
```

## 🧪 Pruebas

### Probar Versión Modular

```bash
cd setup_debian13

# Dry-run (sin hacer cambios)
sudo ./setup_debian13.sh --dry-run

# Ver ayuda
./setup_debian13.sh --help
```

### Compilar Versión Única

```bash
cd setup_debian13

# Compilar
./compile.sh

# Verificar salida
ls -lh setup_debian13_compiled.sh

# Probar compilado
sudo ./setup_debian13_compiled.sh --dry-run
```

## 📋 Mapeo de Artefactos a Archivos

| Artefacto ID | Archivo Destino | Descripción |
|--------------|-----------------|-------------|
| `debian_setup_modular` | `setup_debian13.sh` | Main entry point |
| `lib_config` | `lib/config.sh` | Configuración |
| `lib_logging` | `lib/logging.sh` | Logging |
| `lib_utils` | `lib/utils.sh` | Utilidades |
| `module_system` | `modules/system.sh` | Sistema |
| `module_users` | `modules/users.sh` | Usuarios |
| `module_docker` | `modules/docker.sh` | Docker |
| `module_security` | `modules/security.sh` | Seguridad |
| `module_monitoring` | `modules/monitoring.sh` | Monitoreo |
| `module_checks` | `modules/checks.sh` | Checks |
| `compile_script` | `compile.sh` | Compilador |
| `readme_modular` | `README.md` | Documentación |

## ⚙️ Personalización

Antes de ejecutar, edita `lib/config.sh`:

```bash
# SSH
SSH_PORT=2222  # Cambiar si quieres otro puerto
SSH_ALLOWED_USERS=( "administrator" "deployer" "tuUser" )

# Usuarios
USERS=(
  "administrator:TU_PASSWORD_SEGURO:"
  "deployer:OTRO_PASSWORD:"
  "tuUser:PASSWORD:"
)

# Puertos del firewall
FIREWALL_ALLOWED_PORTS=(
  "${SSH_PORT}/tcp"
  "80/tcp"
  "443/tcp"
  # Añade más si necesitas
)

# Timezone
TIMEZONE="Europe/Madrid"
```

## 🎯 Uso en Producción

### Opción 1: Ejecutar Directamente (Modular)

```bash
# En el servidor
git clone https://tu-repo/setup_debian13.git
cd setup_debian13
sudo ./setup_debian13.sh
```

### Opción 2: Usar Versión Compilada

```bash
# En tu máquina local, compilar primero
cd setup_debian13
./compile.sh

# Subir a servidor web
scp setup_debian13_compiled.sh usuario@servidor:/tmp/

# En el servidor
sudo /tmp/setup_debian13_compiled.sh
```

### Opción 3: Descarga Directa (Más Común)

```bash
# Hospedar en GitHub/GitLab/servidor web
# Luego en el servidor VPS nuevo:
curl -fsSL https://tu-servidor.com/setup_debian13_compiled.sh | sudo bash
```

## 🔍 Troubleshooting

### Error: "No such file or directory"

```bash
# Verificar que todos los archivos existen
ls -la lib/
ls -la modules/

# Verificar permisos
ls -l setup_debian13.sh
# Debe ser: -rwxr-xr-x
```

### Error: "Bad substitution" o sintaxis

```bash
# Verificar que copiaste TODO el contenido
# Cada archivo debe empezar con:
#!/usr/bin/env bash

# Verificar sintaxis
bash -n setup_debian13.sh
bash -n lib/config.sh
```

### El script no encuentra las librerías

```bash
# Asegúrate de ejecutar desde el directorio correcto
cd setup_debian13
pwd  # Debe mostrar: /ruta/a/setup_debian13

# Ejecutar
sudo ./setup_debian13.sh
```

## 📊 Comparación: Monolítico vs Modular

| Aspecto | Monolítico (Original) | Modular (Nuevo) |
|---------|----------------------|-----------------|
| **Líneas** | ~2000 en 1 archivo | ~2000 en 13 archivos |
| **Mantenibilidad** | Difícil | Fácil |
| **Debugging** | Complejo | Simple |
| **Reutilización** | No | Sí |
| **Testing** | Difícil | Por módulos |
| **Colaboración** | Difícil | Fácil |
| **Producción** | ✅ Listo | ✅ Compilar primero |

## 📚 Documentación Adicional

- **README.md**: Documentación completa del proyecto
- **lib/config.sh**: Todas las opciones configurables
- **modules/\*.sh**: Comentarios en cada función

## ✅ Checklist Final

Antes de ejecutar en producción:

- [ ] Todos los 13 archivos creados
- [ ] Permisos correctos (755 para .sh principales, 644 para módulos)
- [ ] `lib/config.sh` personalizado con tus valores
- [ ] Probado con `--dry-run`
- [ ] Si usas versión compilada: ejecutado `./compile.sh`
- [ ] Backup del VPS (por si acaso)
- [ ] Acceso SSH alternativo disponible

## 🎓 Ventajas de esta Arquitectura

1. **Separación de Responsabilidades**: Cada módulo tiene un propósito claro
2. **Fácil Mantenimiento**: Actualizar SSH solo requiere editar `security.sh`
3. **Reutilización**: Los módulos se pueden usar en otros proyectos
4. **Testing**: Puedes probar módulos individuales
5. **Colaboración**: Múltiples personas pueden trabajar en paralelo
6. **Producción**: El compilador genera un único archivo deployable

## 🚨 Importante

- **SIEMPRE** usa `--dry-run` primero
- **SIEMPRE** mantén una sesión SSH abierta mientras pruebas
- **SIEMPRE** verifica que puedes conectar al nuevo puerto SSH antes de cerrar la sesión original

## 💡 Próximos Pasos

1. Crear todos los archivos según esta guía
2. Verificar con `verify_structure.sh`
3. Probar con `--dry-run`
4. Compilar para producción
5. Deploy en tu VPS de OVH

---

**¿Necesitas ayuda?** Revisa los artefactos proporcionados o pregunta por cualquier paso específico.