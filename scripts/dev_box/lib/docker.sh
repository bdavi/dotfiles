#!/usr/bin/env bash

######################################################################
# Docker (official apt repo)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh.
######################################################################

# Installs Docker Engine, the Compose v2 and Buildx plugins from Docker's
# own apt repo (Ubuntu's docker.io package lags behind and only ships the
# old standalone docker-compose) and adds the current user to the docker
# group so containers can be run without sudo. Every step here is
# idempotent on its own (apt-get install, overwriting the same key/repo
# file, usermod -aG, systemctl enable --now), so this is safe to re-run.
#
# The docker group membership only takes effect in new login sessions -
# log out and back in (or `newgrp docker`) before running docker without
# sudo.
install_docker() {
  # Older/conflicting packages the official docs recommend clearing out
  # first - guarded since none of these are in this repo's own install
  # lists and likely aren't present.
  local pkg
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    if dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'; then
      sudo apt-get --yes purge "$pkg"
    fi
  done

  sudo apt-get --yes install ca-certificates curl

  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get --yes install \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  sudo usermod -aG docker "$USER"
  sudo systemctl enable --now docker
}
