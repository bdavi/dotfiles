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

  # The code package's postinst maintains its own repo entry -
  # /etc/apt/sources.list.d/vscode.sources, marked "AUTOMATICALLY
  # CONFIGURED", signed by /usr/share/keyrings/microsoft.gpg. The
  # keyring + vscode.list written here only exist to bootstrap the
  # first install: once the auto-managed file appears, keeping ours
  # around defines the repo twice with different keyrings and every
  # apt call fails with "Conflicting values set for option Signed-By".
  # So bootstrap only when the auto-managed file isn't there, and drop
  # the bootstrap immediately after installing (build_ubuntu.sh's repo
  # hygiene step also clears it, covering anything in between).
  if [[ ! -f /etc/apt/sources.list.d/vscode.sources ]]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor \
      | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
    sudo chmod a+r /etc/apt/keyrings/packages.microsoft.gpg

    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  fi

  sudo apt-get update
  sudo apt-get --yes install code

  if [[ -f /etc/apt/sources.list.d/vscode.sources ]]; then
    sudo rm -f /etc/apt/sources.list.d/vscode.list \
      /etc/apt/keyrings/packages.microsoft.gpg
  fi
}
