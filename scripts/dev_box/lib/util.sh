#!/usr/bin/env bash

################################################################################
# Shared constants and functions for the dev_box build/update scripts
################################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh and
# ubuntu_maintenance.sh.
################################################################################

set -euo pipefail

UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$UTIL_DIR/../../.." && pwd)"

# Fails the script if the current user can't sudo. Interactively (a real
# terminal), prompts once and caches the credential (with a background
# keepalive) so later `sudo` calls in the same script don't stop to
# re-prompt. Non-interactively (e.g. cron - see install_update_cron_job),
# there's no TTY to prompt on, so this only succeeds if apt-get is already
# passwordless for this user (see install_unattended_apt_sudo).
require_sudo() {
  if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root/sudo." >&2
    exit 1
  fi

  if [[ -t 0 ]]; then
    if ! sudo -v; then
      echo "This script requires sudo privileges." >&2
      exit 1
    fi

    while true; do
      sudo -n true
      sleep 60
      kill -0 "$$" 2>/dev/null || exit
    done 2>/dev/null &
  else
    if ! sudo -n apt-get --version >/dev/null 2>&1; then
      echo "Running non-interactively, but apt-get isn't passwordless for this user (see install_unattended_apt_sudo)." >&2
      exit 1
    fi
  fi
}

# Refreshes the apt index and upgrades installed packages within the
# current Ubuntu release. full-upgrade (not plain upgrade) so dependency
# changes - e.g. a kernel transition - are handled instead of refused.
# This can never trigger a distro version upgrade on its own: that only
# happens via `do-release-upgrade` or by pointing sources.list at a new
# release, neither of which this touches.
update_os_packages() {
  sudo apt-get update

  sudo DEBIAN_FRONTEND=noninteractive apt-get --yes \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade

  if [[ -f /var/run/reboot-required ]]; then
    echo "A reboot is required to finish applying updates." >&2
  fi
}

# Checks for broken dependencies (read-only - reports, doesn't fix), then
# removes packages left orphaned by upgrades - including old kernels no
# longer needed, which apt's own dependency tracking handles safely on its
# own (it won't touch the running kernel or the fallback one); a
# hand-rolled "keep N kernels" script is a common way to end up unable to
# boot, so this deliberately doesn't try to be cleverer than apt here.
# Also clears out cached .deb files for packages no longer installable at
# that version, freeing disk without touching anything still in use.
clean_os_packages() {
  sudo apt-get check
  sudo apt-get --yes autoremove --purge
  sudo apt-get autoclean
}
