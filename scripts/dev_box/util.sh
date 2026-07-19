#!/usr/bin/env bash

#############################################################################
# Shared constants and functions for the dev_box build/update scripts
#############################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh and
# update_ubuntu.sh.
#############################################################################

set -euo pipefail

UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$UTIL_DIR/../.." && pwd)"

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

# Latest release tag for a GitHub repo, pinned to a major version, e.g.
#   github_latest_release asdf-vm/asdf 0   ->  v0.20.0
github_latest_release() {
  local repo="$1"
  local major_version="$2"

  curl -fsSL "https://api.github.com/repos/${repo}/releases" \
    | grep -o '"tag_name": *"v[^"]*"' \
    | sed -E 's/.*"(v[^"]+)".*/\1/' \
    | grep -E "^v${major_version}\." \
    | sort -V \
    | tail -n1
}

# GitHub release asset architecture naming (amd64/arm64) for this machine.
release_arch() {
  case "$(uname -m)" in
    x86_64) echo amd64 ;;
    aarch64) echo arm64 ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      return 1
      ;;
  esac
}
