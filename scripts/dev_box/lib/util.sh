#!/usr/bin/env bash

################################################################################
# Shared constants and functions for the dev_box build/update scripts
################################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh and
# update_ubuntu.sh.
################################################################################

set -euo pipefail

UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$UTIL_DIR/../../.." && pwd)"

# Fails the script if the current user can't sudo, then caches the
# credential (with a background keepalive) so later `sudo` calls in the
# same script don't stop to prompt for a password.
require_sudo() {
  if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root/sudo." >&2
    exit 1
  fi

  if ! sudo -v; then
    echo "This script requires sudo privileges." >&2
    exit 1
  fi

  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
  done 2>/dev/null &
}
