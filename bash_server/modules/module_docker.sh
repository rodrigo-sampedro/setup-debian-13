#!/usr/bin/env bash
# Docker installation and deployment helpers.

create_docker_helper_scripts() {
  log "Creating Docker helper scripts"

  if $DRY_RUN; then
    log "[DRY-RUN] Would create Docker helper scripts"
    return 0
  fi

  cat > /usr/local/bin/docker-deploy <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

case "${1:-}" in
  start) shift; docker compose -f "$@" up -d ;;
  stop) shift; docker compose -f "$@" down ;;
  restart) shift; docker compose -f "$@" restart ;;
  logs) shift; docker compose -f "$@" logs -f ;;
  pull) shift; docker compose -f "$@" pull ;;
  *) echo "Usage: $0 {start|stop|restart|logs|pull} <compose-file>" >&2; exit 1 ;;
esac
EOF

  cat > /usr/local/bin/docker-manage <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

case "${1:-}" in
  ps) shift; docker ps "$@" ;;
  images) docker images ;;
  stats) docker stats --no-stream ;;
  logs) shift; docker logs "$@" ;;
  *) echo "Usage: $0 {ps|images|stats|logs}" >&2; exit 1 ;;
esac
EOF

  chmod 0755 /usr/local/bin/docker-deploy /usr/local/bin/docker-manage
}

setup_docker_aliases() {
  log "Setting up Docker command aliases"

  for entry in "${USERS[@]}"; do
    IFS=":" read -r user _ _ <<<"$entry"
    if ! id "$user" >/dev/null 2>&1; then
      continue
    fi
    if $DRY_RUN; then
      log "[DRY-RUN] Would setup aliases for $user"
      continue
    fi
    blockinfile_marker="# BEGIN DEBIAN SETUP DOCKER ALIASES"
    if ! grep -qF "$blockinfile_marker" "/home/$user/.bashrc" 2>/dev/null; then
      cat >> "/home/$user/.bashrc" <<EOF

$blockinfile_marker
alias dp='docker-deploy'
alias dm='docker-manage'
# END DEBIAN SETUP DOCKER ALIASES
EOF
      chown "$user:$user" "/home/$user/.bashrc"
    fi
  done
}

install_docker() {
  log "Installing Docker"

  if command_exists docker; then
    ok "Docker already installed"
    return 0
  fi
  if $DRY_RUN; then
    log "[DRY-RUN] Would install Docker packages"
    return 0
  fi

  run apt-get update
  run apt-get install -y docker.io docker-compose-plugin
  systemctl enable docker
  systemctl start docker
}

configure_docker_daemon() {
  log "Configuring Docker daemon"

  if $DRY_RUN; then
    log "[DRY-RUN] Would configure Docker daemon"
    return 0
  fi

  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {"max-size": "10m", "max-file": "3"},
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF
  systemctl restart docker
}

setup_docker_projects_dir() {
  log "Setting up Docker projects directory"

  if $DRY_RUN; then
    log "[DRY-RUN] Would create ${DOCKER_DEPLOY_BASE_DIR}"
    return 0
  fi

  install -d -m 2775 -o root -g "$DOCKER_DEPLOY_GROUP" "$DOCKER_DEPLOY_BASE_DIR"
  install -d -m 2775 -o root -g "$DOCKER_DEPLOY_GROUP" \
    "$DOCKER_DEPLOY_BASE_DIR/.env" "$DOCKER_DEPLOY_BASE_DIR/volumes"
}
