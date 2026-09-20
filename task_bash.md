# Plan de trabajo Bash

## Objetivo

Alinear `bash_server/` con `AGENT_FRAMEWORK_SPEC.md` y convertir el script compilado en el artefacto reproducible que se ejecuta en el servidor real. La configuracion demo servira como plantilla documentada, pero nunca se incrustara como secreto efectivo en la version de produccion.

## Decisiones de diseño

- El bootstrap inicial puede aceptar una contraseña temporal del proveedor mediante entrada interactiva segura o un mecanismo externo. No se escribira en el repositorio, en el script compilado ni en logs.
- El script debe instalar y verificar la clave publica del operador antes de desactivar autenticacion por contraseña.
- `deployer` puede tener root temporal durante la primera version mediante una bandera explicita de bootstrap. El estado final debe ofrecer una politica allowlist y una tarea de reduccion.
- `administrator` se crea para recuperacion controlada, no se incluye en `AllowUsers`, se bloquea al completar el setup y solo se activa mediante un procedimiento auditado.
- El compilado se genera desde la fuente modular y recibe los valores reales de forma segura al ejecutarse. No se deben copiar manualmente contraseñas o claves al archivo compilado.

## Estrategia de configuracion

### Plantillas versionadas

Crear archivos de ejemplo sin secretos:

- `bash_server/config.example.env`
- `bash_server/README` o documentacion de variables
- `bash_server/test-fixtures/` para pruebas locales no productivas

Los ejemplos pueden conservar nombres y valores claramente ficticios como `CHANGE_ME`, pero no contraseñas con apariencia real ni credenciales reutilizables.

### Configuracion real fuera del repositorio

Soportar una de estas fuentes, en orden de preferencia:

1. Variables de entorno proporcionadas por el operador o un gestor de secretos.
2. Archivo local protegido, por ejemplo `/root/.config/debian-setup/server.env`, con propietario root y modo `0600`.
3. Entrada interactiva para la contraseña de bootstrap y rutas de claves.

El script debe validar el origen, permisos y presencia de valores requeridos antes de cambiar SSH. Nunca debe registrar contraseñas, claves privadas, tokens ni el contenido completo de archivos de secretos.

## Fases y tareas

### Fase 1: sanear la fuente y eliminar drift

- [ ] Eliminar contraseñas demo de `lib/config.sh`, `create_all_script.sh` y cualquier documentación operativa.
- [ ] Sustituir configuracion fija por variables de entorno/archivo protegido con valores obligatorios.
- [ ] Definir nombres estables de usuarios y eliminar diferencias entre `tuUser`, `ropnom` y valores antiguos.
- [ ] Corregir `verify_structure.sh` para que use la estructura real `bash_server/` y `bash_server/compiled/`.
- [ ] Corregir el destino de `compile_script.sh` para escribir explicitamente en `bash_server/compiled/`.
- [ ] Regenerar el compilado y comprobar que no quedan valores de la configuracion de desarrollo.
- [ ] Normalizar finales de linea a LF para todos los scripts ejecutados en Debian.

**Aceptacion:** fuente y compilado coinciden en estructura y politica; una compilacion limpia produce el mismo resultado verificable y `bash -n` funciona en Debian/WSL.

### Fase 2: bootstrap inicial autenticado

- [ ] Añadir un modo `--bootstrap` separado del modo de hardening final.
- [ ] Solicitar la contraseña sin mostrarla ni guardarla, o recibirla desde stdin/descriptor seguro cuando se ejecute de forma no interactiva.
- [ ] Validar Debian 13, root efectivo y disponibilidad de `ssh-keygen`, `sshd`, `sudo` y `ufw` antes de proceder.
- [ ] Crear `deployer` y cargar su clave publica desde parametro seguro o archivo local validado.
- [ ] Crear `administrator` bloqueado para SSH y conservar su clave solo para el procedimiento de recuperacion controlada.
- [ ] Verificar desde una segunda conexion que `deployer` puede entrar con clave antes de aplicar `PasswordAuthentication no`.
- [ ] Desactivar o bloquear el usuario `debian` para SSH cuando la transicion este confirmada.

**Aceptacion:** el bootstrap falla de forma segura si no hay clave publica, si la conexion por clave no se verifica o si el host no es Debian 13.

### Fase 3: privilegios y SSH

- [ ] Introducir `BOOTSTRAP_DEPLOYER_ROOT=true` como excepcion temporal, con mensaje de advertencia, log de auditoria y salida visible.
- [ ] Separar la politica final `deployer` allowlist de la politica temporal.
- [ ] Generar sudoers en archivo temporal, validar con `visudo -cf` y moverlo atomicamente.
- [ ] No incluir `administrator` en `SSH_ALLOWED_USERS`/`AllowUsers`.
- [ ] Aplicar `PermitRootLogin no`, `PasswordAuthentication no` y el nuevo puerto solo despues de la prueba de clave.
- [ ] Crear comandos o funciones separados para activar y desactivar `administrator`, con duracion, motivo y registro.
- [ ] Revisar que los logs no impriman contraseñas ni configuracion sensible completa.

**Aceptacion:** el estado final se puede administrar por clave con `deployer`, `administrator` esta bloqueado y cada cambio de privilegios es comprobable.

### Fase 4: firewall y servicios

- [ ] Hacer que los puertos se declaren por clase de exposicion y no como lista fija.
- [ ] Mantener deny incoming y no abrir `22`, `80` o `443` salvo que exista una justificacion declarada.
- [ ] Alinear Fail2ban con el puerto SSH efectivo y validar que el jail arranca.
- [ ] Evitar descargar scripts remotos no fijados; eliminar `curl | bash` y exigir checksum/firma para herramientas externas.
- [ ] Revisar Endlessh, GeoIP y forwarding para que no abran una superficie no declarada.
- [ ] Configurar Docker sin host networking, privilegios innecesarios ni montajes no documentados.

**Aceptacion:** `ss -tulpn`, `ufw status verbose` y los servicios activos coinciden con la matriz de exposicion del proyecto.

### Fase 5: compilado de produccion

- [ ] Definir el compilador como transformacion determinista de fuentes, sin inyectar secretos.
- [ ] Permitir que el compilado lea configuracion segura en tiempo de ejecucion.
- [ ] Añadir un encabezado de version, commit/fingerprint de fuentes y fecha de compilacion no sensible.
- [ ] Añadir una comprobacion que falle si el compilado contiene patrones de contraseñas, claves privadas, tokens o valores `CHANGE_ME`.
- [ ] Generar el artefacto en `bash_server/compiled/` y revisar el diff antes de distribuirlo.
- [ ] Mantener el compilado como artefacto versionado solo si el proyecto decide que esa es la politica; en caso contrario distribuirlo desde un pipeline firmado.
- [ ] Verificar el checksum/firma del compilado antes de ejecutarlo en el servidor real.

**Aceptacion:** el servidor real ejecuta un compilado generado reproduciblemente desde la fuente, y los secretos solo aparecen en el entorno protegido del host.

### Fase 6: backup, restore y redeploy

- [ ] Separar backups de configuracion, referencias de secretos y datos de servicios.
- [ ] Proteger el backup con permisos, cifrado, retencion y destino documentados.
- [ ] Crear un modo de exportar un manifiesto de configuracion no secreta y una lista de secretos requeridos.
- [ ] Probar restore en un Debian 13 limpio.
- [ ] Medir bootstrap y redeploy frente a los objetivos de 30 y 60 minutos.

**Aceptacion:** el redeploy no depende de editar `lib/config.sh` en el servidor ni de conocer pasos manuales no documentados.

## Validacion Bash obligatoria

Ejecutar en Debian 13 o WSL con dependencias disponibles:

```bash
find bash_server -type f -name '*.sh' -print0 | xargs -0 dos2unix
bash -n bash_server/debian_setup_modular.sh
bash -n bash_server/compile_script.sh
for file in bash_server/lib/*.sh bash_server/modules/*.sh; do bash -n "$file"; done
shellcheck bash_server/debian_setup_modular.sh bash_server/compile_script.sh bash_server/lib/*.sh bash_server/modules/*.sh
bash_server/compile_script.sh
bash -n bash_server/compiled/setup_debian13.sh
bash_server/compiled/setup_debian13.sh --help
bash_server/compiled/setup_debian13.sh --dry-run
```

Despues, en una maquina de prueba Debian 13:

```bash
sudo bash_server/compiled/setup_debian13.sh --bootstrap --dry-run
sudo bash_server/compiled/setup_debian13.sh --bootstrap
sudo ss -tulpn
sudo ufw status verbose
sudo sshd -t
sudo visudo -cf /etc/sudoers.d/deployer
```

## Bloqueadores de release

- Contraseñas demo incrustadas en el fuente o compilado.
- Compilado diferente de la fuente modular sin una razon y evidencia.
- `administrator` accesible directamente por SSH.
- `deployer` con root permanente sin excepcion documentada y plan de reduccion.
- Desactivar password authentication sin verificar clave desde una segunda sesion.
- Sudoers generado sin `visudo`.
- Ejecucion remota de scripts sin pinning, checksum o firma.
- Artefacto compilado sin checksum/firma o con secretos incrustados.
