# Plan de trabajo Ansible

## Objetivo

Alinear `ansible/` con `AGENT_FRAMEWORK_SPEC.md` sin perder el flujo de bootstrap inicial por contraseña. Las credenciales demo se conservaran solamente como ejemplos no utilizables; las credenciales reales se inyectaran desde Vault o archivos locales ignorados por Git.

## Decisiones de diseño

- El primer acceso al servidor Debian 13 puede usar temporalmente el usuario de provision inicial (`debian` o el usuario indicado por el proveedor) y contraseña.
- Durante esa ventana Ansible debe instalar la clave publica autorizada, verificar el acceso por clave desde el operador y solo despues deshabilitar autenticacion por contraseña.
- `deployer` podra tener `sudo` amplio durante la primera version para facilitar el despliegue. Esta excepcion debe estar controlada por una variable de bootstrap, quedar registrada y tener una tarea posterior para reducirlo a una allowlist.
- `administrator` se crea durante el bootstrap como cuenta de recuperacion, pero queda bloqueado para SSH y deshabilitado al terminar la configuracion. La activacion futura sera un procedimiento separado, temporal y auditado.
- Los valores de ejemplo nunca deben ser la fuente de variables efectiva en un host real.

## Estrategia de configuracion y secretos

### Archivos versionados

Crear ejemplos sin secretos reales:

- `ansible/inventory/hosts.yaml.example`
- `ansible/vars/main.yml.example`
- `ansible/vars/users.yml.example`
- `ansible/vars/security.yml.example`
- `ansible/group_vars/all/README.md` o documentacion equivalente

Los ejemplos deben contener marcadores como `CHANGE_ME`, nunca contraseñas plausibles ni claves privadas.

### Archivos locales no versionados

Definir y documentar:

- `ansible/inventory/hosts.yaml` para hosts reales.
- `ansible/vars/vault.yml` cifrado con `ansible-vault`.
- `.vault_pass` fuera del repositorio o proporcionado por el gestor de secretos.
- `ansible/vars/users.local.yml` solo si se necesita separar datos operativos no cifrados; debe estar en `.gitignore` y no debe contener secretos que Vault pueda cubrir.

Agregar reglas de `.gitignore` para inventarios reales, contraseñas Vault, logs, retries, claves privadas y archivos generados. Agregar una comprobacion automatica que falle si aparecen patrones de contraseñas, tokens o claves privadas en archivos versionables.

### Modelo minimo de secretos

Definir en Vault, sin valores por defecto inseguros:

- `vault_bootstrap_password` solo para la primera conexion.
- `vault_deployer_password` si la politica temporal exige password local.
- hashes de contrasena, nunca contraseñas en texto plano cuando no sean necesarias.
- `vault_authorized_keys` o claves publicas parametrizadas por usuario.
- credenciales de backup, VPN y TLS cuando se implementen.

Si falta la clave publica o el secreto requerido, el playbook debe fallar antes de tocar SSH o firewall.

## Fases y tareas

### Fase 1: saneamiento y contrato de variables

- [x] Corregir el grupo objetivo del inventario para que coincida con `site.yml` (`vps_servers`) o parametrizarlo de forma consistente.
- [x] Eliminar rutas locales de otros equipos y credenciales comentadas del inventario.
- [x] Separar ejemplos de configuracion de valores operativos.
- [x] Completar variables actualmente ausentes: puerto SSH, usuarios permitidos, backup, timezone, paquetes, Docker y puertos del firewall.
- [x] Corregir `ansible.cfg`: seccion duplicada, valores mal escritos, inventario real, uso de `ForwardAgent` y gestion de la vault password.
- [x] Hacer que la ejecucion falle si faltan las claves publicas requeridas.

**Aceptacion:** `ansible-inventory --graph` y `ansible-inventory --list` funcionan con el inventario de ejemplo; no hay secretos ni rutas de otra maquina en archivos versionados.

### Fase 2: bootstrap inicial por contraseña

- [x] Crear una fase/tag `bootstrap` que use el usuario inicial del proveedor.
- [x] Mantener la contraseña fuera del inventario mediante `--ask-pass` en el runner.
- [ ] Verificar Debian 13 y privilegios antes de crear usuarios.
- [x] Crear `deployer` con la clave publica definida.
- [x] Crear `administrator` con home, shell y clave de recuperacion, pero con cuenta bloqueada y sin acceso SSH directo.
- [ ] Mantener `debian` como bootstrap-only y preparar su bloqueo SSH al final de la transicion.
- [ ] No aplicar `PasswordAuthentication no` hasta haber verificado una conexion SSH por clave en una segunda sesion.

**Aceptacion:** una instalacion limpia puede pasar de acceso inicial por contraseña a acceso por clave sin perder la sesion de emergencia ni bloquear al operador.

### Fase 3: acceso, privilegios y hardening

- [ ] Parametrizar `ssh_authorized_keys` por usuario y prohibir `ssh_key_url` remoto sin una politica de integridad aprobada.
- [ ] Excluir `administrator` de `AllowUsers` y asegurar `AllowGroups`/reglas equivalentes.
- [ ] Aplicar `PermitRootLogin no`, `PasswordAuthentication no` y el puerto configurado solo despues de la verificacion de clave.
- [ ] Crear una politica temporal de `deployer` root mediante una variable explicita, por ejemplo `bootstrap_deployer_root: true`, con advertencia visible y registro de auditoria.
- [ ] Añadir una politica final allowlist para `deployer`, usando comandos o wrappers revisados y validados con `visudo`.
- [ ] Crear tareas de activacion/desactivacion de `administrator` con expiracion, evidencia y sin acceso SSH directo.
- [ ] Asegurar que los usuarios no se creen con contraseñas demo por defecto.
- [ ] Validar sudoers con `visudo -cf` y comprobar permisos efectivos, no solo la existencia del archivo.

**Aceptacion:** el estado final usa claves, `administrator` no entra por SSH, `deployer` tiene exactamente la politica seleccionada y las tareas dejan evidencia.

### Fase 4: firewall, Docker y exposicion

- [ ] Mantener UFW con deny incoming y abrir solo el puerto SSH y servicios declarados.
- [ ] No abrir `80/443` por defecto si no existe reverse proxy, TLS, dominio y politica de logs.
- [ ] Separar puertos publicos, VPN-only e internos mediante variables de exposicion.
- [ ] Fijar version o digest de imagenes Docker cuando se agreguen servicios.
- [ ] Revisar los wrappers Docker: `docker exec`, `prune` y acceso a Docker pueden equivaler a root.
- [ ] Documentar propietario, redes, volumenes, secretos, healthchecks, restart policy y backup class por servicio.

**Aceptacion:** la lista de puertos y redes coincide con la exposicion declarada y no existen puertos abiertos por conveniencia.

### Fase 5: backup, restore y redeploy

- [ ] Separar backup de configuracion/IaC, secretos referenciados y datos de servicios.
- [ ] Eliminar `ignore_errors` en copias criticas o convertirlo en validacion explicita con resultado bloqueante.
- [ ] Definir cifrado, retencion, destino y permisos del backup.
- [ ] Implementar una prueba de restauracion automatizada.
- [ ] Documentar y medir el redeploy en host Debian 13 limpio.

**Aceptacion:** existe evidencia de restore y la secuencia completa puede repetirse sin credenciales o pasos manuales ocultos.

## Validacion Ansible obligatoria

Ejecutar en un entorno Debian 13 o WSL preparado:

```bash
ansible-playbook --syntax-check -i inventory/hosts.yaml site.yml
ansible-inventory -i inventory/hosts.yaml --list
ansible-playbook -i inventory/hosts.yaml site.yml --check --diff --ask-vault-pass
ansible-playbook -i inventory/hosts.yaml site.yml --tags bootstrap,users,ssh --check --diff --ask-vault-pass
ansible-playbook -i inventory/hosts.yaml site.yml --check --diff --ask-vault-pass
ansible-playbook -i inventory/hosts.yaml site.yml --check --diff --ask-vault-pass
```

La ultima ejecucion debe producir cero cambios esperados en el estado ya configurado. Ademas se debe probar la conexion por clave desde una segunda terminal antes del cambio de SSH.

## Bloqueadores de release

- Secretos demo usados como valores efectivos.
- Inventario con credenciales o rutas personales.
- `administrator` accesible por SSH.
- `deployer` con root permanente sin flag, justificacion y plan de reduccion.
- `PasswordAuthentication no` aplicado sin clave verificada.
- Puertos publicos sin exposicion, TLS y logging definidos.
- Backup sin restore probado.
