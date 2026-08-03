#!/usr/bin/env bash

######################################################################
# VS Code (official apt repo)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
######################################################################

# Installs VS Code from Microsoft's own apt repo - no Ubuntu package
# exists, so this mirrors install_docker/install_github_cli (docker.sh,
# github_cli.sh): a signed keyring plus a sources.list.d entry. Every
# step here is idempotent (overwriting the same key/repo file,
# apt-get install), so this is safe to re-run.
install_vscode() {
  sudo apt-get --yes install curl gpg

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
  sudo chmod a+r /etc/apt/keyrings/packages.microsoft.gpg

  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

  sudo apt-get update
  sudo apt-get --yes install code
}
