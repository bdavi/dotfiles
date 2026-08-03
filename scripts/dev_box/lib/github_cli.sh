#!/usr/bin/env bash

######################################################################
# GitHub CLI (official apt repo)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
######################################################################

# Installs gh from GitHub's own apt repo, not Ubuntu's universe package
# (gh 2.46.0 there vs. 2.96.0 upstream at time of writing - the same gap
# that has install_docker (docker.sh) prefer Docker's own repo over
# docker.io). Every step here is idempotent (overwriting the same key/
# repo file, apt-get install), so this is safe to re-run.
install_github_cli() {
  sudo apt-get --yes install curl

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

  sudo apt-get update
  sudo apt-get --yes install gh
}
