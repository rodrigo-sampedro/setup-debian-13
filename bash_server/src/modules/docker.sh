#!/usr/bin/env bash
# =============================================================================
# modules/docker.sh - Instalación y Configuración de Docker
# =============================================================================

create_docker_helper_scripts() {
  log "Creating Docker helper scripts"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would create Docker helper scripts"
    return 0
  fi
  
  cat > /usr/local/bin/docker-deploy << 'EOF'
#!/bin/bash
# Safe Docker deployment script
set -e

case "$1" in
  start)
    shift
    docker compose -f "$@" up -d
    ;;
  stop)
    shift
    docker compose -f "$@" down
    ;;
  restart)
    shift
    docker compose -f "$@" restart
    ;;
  logs)
    shift
    docker compose -f "$@" logs -f
    ;;
  pull)
    shift
    docker compose -f "$@" pull
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|logs|pull} <compose-file>"
    exit 1
    ;;
esac
EOF

  cat > /usr/local/bin/docker-manage << 'EOF'
#!/bin/bash
# Safe Docker management script
set -e

case "$1" in
  ps)
    shift
    docker ps "$@"
    ;;
  images)
    docker images
    ;;
  prune)
    docker system prune -f
    ;;
  stats)
    docker stats --no-stream
    ;;
  logs)
    shift
    docker logs "$@"
    ;;
  *)
    echo "Usage: $0 {ps|images|prune|stats|logs}"
    exit 1
    ;;
esac
EOF

  chmod 755 /usr/local/bin/docker-deploy
  chmod 755 /usr/local/bin/docker-manage
  
  ok "Docker helper scripts created in /usr/local/bin/"
}

setup_docker_aliases() {
  log "Setting up Docker command aliases for users"
  
  for entry in "${USERS[@]}"; do
    IFS=":" read -r user pass sshkey <<<"$entry"
    
    if ! id "$user" &>/dev/null; then
      warn "User $user doesn't exist, skipping alias setup"
      continue
    fi
    
    if $DRY_RUN; then
      log "[DRY-RUN] Would setup aliases for $user"
      continue
    fi
    
    local user_home
    user_home=$(eval echo "~$user")
    local bashrc="$user_home/.bashrc"
    
    if grep -q "alias dp=" "$bashrc" 2>/dev/null; then
      ok "Docker aliases already configured for $user"
      continue
    fi
    
    cat >> "$bashrc" << 'EOF'

# Docker helper aliases
alias dp='docker-deploy'
alias dm='docker-manage'

# Show last login
if [ -f ~/.last_login ]; then
    echo "Last login: $(cat ~/.last_login)"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S from '$(echo $SSH_CONNECTION | awk '{print $1}'))" > ~/.last_login
EOF
    
    chown "$user:$user" "$bashrc"
    ok "Docker aliases configured for $user (dp, dm)"
  done
}

install_docker() {
  log "Installing Docker from official repository"
  
  if command_exists docker; then
    ok "Docker already installed"
    return 0
  fi
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would install Docker"
    return 0
  fi
  
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  run apt update
  run apt install -y "${DOCKER_PACKAGES[@]}"
  
  systemctl start docker
  systemctl enable docker
  
  ok "Docker installed and enabled"
}

configure_docker_daemon() {
  log "Configuring Docker daemon for security"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would configure Docker daemon"
    return 0
  fi
  
  mkdir -p /etc/docker
  
  cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF

  systemctl restart docker
  ok "Docker daemon configured"
}

setup_docker_projects_dir() {
  log "Setting up Docker projects directory"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would create ${DOCKER_DEPLOY_BASE_DIR}"
    return 0
  fi
  
  if [[ ! -d "$DOCKER_DEPLOY_BASE_DIR" ]]; then
    mkdir -p "$DOCKER_DEPLOY_BASE_DIR"
  fi
  
  chown root:"${DOCKER_DEPLOY_GROUP}" "$DOCKER_DEPLOY_BASE_DIR"
  chmod 2775 "$DOCKER_DEPLOY_BASE_DIR"
  
  mkdir -p "$DOCKER_DEPLOY_BASE_DIR"/{.env,volumes}
  chown -R root:"${DOCKER_DEPLOY_GROUP}" "$DOCKER_DEPLOY_BASE_DIR"/{.env,volumes}
  chmod -R 2775 "$DOCKER_DEPLOY_BASE_DIR"/{.env,volumes}
  
  cat > "$DOCKER_DEPLOY_BASE_DIR/README.md" << EOF
# Docker Projects Directory

This directory is shared among users in the '${DOCKER_DEPLOY_GROUP}' group.

## Structure:
- \`.env/\` - Environment files for docker-compose
- \`volumes/\` - Docker volumes data
- Each project should have its own subdirectory

## Usage:
- Use 'dp' (docker-deploy) to manage compose files
- Use 'dm' (docker-manage) for container operations

## Examples:
\`\`\`bash
# Start a project
dp start /path/to/docker-compose.yml

# Check running containers
dm ps

# View logs
dm logs container_name
\`\`\`
EOF
  
  chown root:"${DOCKER_DEPLOY_GROUP}" "$DOCKER_DEPLOY_BASE_DIR/README.md"
  chmod 664 "$DOCKER_DEPLOY_BASE_DIR/README.md"
  
  ok "Docker projects directory configured at ${DOCKER_DEPLOY_BASE_DIR}"
}