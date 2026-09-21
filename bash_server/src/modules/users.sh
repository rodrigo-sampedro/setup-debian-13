#!/usr/bin/env bash
# =============================================================================
# modules/users.sh - Gestión de Usuarios
# =============================================================================

prompt_password() {
  local user="$1"
  local pass1 pass2

  exec < /dev/tty

  while true; do
    echo ""
    echo "Enter password for $user:"
    read -rs pass1
    echo ""
    echo "Confirm password for $user:"
    read -rs pass2
    echo ""

    if [[ -z "$pass1" ]]; then
      echo "Password cannot be empty"
      continue
    fi

    if [[ "$pass1" != "$pass2" ]]; then
      echo "Passwords do not match, try again"
      continue
    fi

    break
  done

  printf '%s' "$pass1"
}

create_docker_deploy_group() {
  log "Creating docker_deploy group for shared Docker projects"
  
  if $DRY_RUN; then
    log "[DRY-RUN] Would create group: ${DOCKER_DEPLOY_GROUP}"
    return 0
  fi
  
  if getent group "${DOCKER_DEPLOY_GROUP}" >/dev/null; then
    ok "Group ${DOCKER_DEPLOY_GROUP} already exists"
  else
    groupadd "${DOCKER_DEPLOY_GROUP}"
    ok "Group ${DOCKER_DEPLOY_GROUP} created"
  fi
}

create_users() {
  log "Creating system users"
  
  for entry in "${USERS[@]}"; do
    IFS=":" read -r user pass sshkey <<<"$entry"

    if id "$user" &>/dev/null; then
      ok "User $user already exists"
      
      if ! groups "$user" | grep -q "${DOCKER_DEPLOY_GROUP}"; then
        if ! $DRY_RUN; then
          usermod -aG "${DOCKER_DEPLOY_GROUP}" "$user"
          ok "Added $user to ${DOCKER_DEPLOY_GROUP} group"
        else
          log "[DRY-RUN] Would add $user to ${DOCKER_DEPLOY_GROUP} group"
        fi
      fi
      continue
    fi

    if $DRY_RUN; then
      log "[DRY-RUN] Would create user: $user"
      continue
    fi

    if useradd -m -s /bin/bash -G "${DOCKER_DEPLOY_GROUP}" "$user" &>>"$LOG_FILE"; then
      ok "User $user created"
    else
      fail "Failed to create user $user"
    fi

    if [[ -z "$pass" ]]; then
      pass="$(prompt_password "$user")"
    fi

    if printf '%s:%s\n' "$user" "$pass" | chpasswd 2>>"$LOG_FILE"; then
      ok "Password set for $user"
    else
      warn "Failed to set password for $user - check log file"
    fi

    ok "User $user setup completed (member of ${DOCKER_DEPLOY_GROUP})"
  done
}

setup_ssh_keys() {
  log "Setting up SSH keys for users"
  
  for entry in "${USERS[@]}"; do
    IFS=":" read -r user pass sshkey <<<"$entry"
    
    [[ -z "$sshkey" ]] && continue
    
    if ! id "$user" &>/dev/null; then
      warn "User $user doesn't exist, skipping SSH key setup"
      continue
    fi
    
    if $DRY_RUN; then
      log "[DRY-RUN] Would setup SSH key for $user from: $sshkey"
      continue
    fi
    
    local user_home
    user_home=$(eval echo "~$user")
    local ssh_dir="$user_home/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"
    
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    if [[ "$sshkey" =~ ^https?:// ]]; then
      log "Downloading SSH key from URL for $user"
      curl -fsSL "$sshkey" >> "$auth_keys" 2>>"$LOG_FILE" || warn "Failed to download SSH key for $user"
    elif [[ -f "$sshkey" ]]; then
      log "Copying SSH key from file for $user"
      cat "$sshkey" >> "$auth_keys"
    else
      warn "SSH key not found: $sshkey"
      continue
    fi
    
    chmod 600 "$auth_keys"
    chown -R "$user:$user" "$ssh_dir"
    
    ok "SSH key configured for $user"
  done
}

configure_sudo() {
  log "Configuring sudo policies"
  
  for rule in "${SUDO_RULES[@]}"; do
    IFS=":" read -r user policy <<<"$rule"
    
    local sudoers_file="/etc/sudoers.d/$user"
    
    if $DRY_RUN; then
      log "[DRY-RUN] Would configure sudo for $user: $policy"
      continue
    fi
    
    if [[ -f "$sudoers_file" ]]; then
      if grep -Fxq "$user $policy" "$sudoers_file"; then
        ok "Sudo already configured for $user (unchanged)"
        continue
      else
        log "Updating sudo policy for $user"
      fi
    fi
    
    echo "$user $policy" > "$sudoers_file"
    chmod 0440 "$sudoers_file"
    ok "Sudo configured for $user"
  done
}