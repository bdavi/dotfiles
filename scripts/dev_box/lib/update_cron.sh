#!/usr/bin/env bash

######################################################################
# Unattended build_ubuntu.sh cron setup
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh
# (needs DOTFILES_DIR).
######################################################################

# Grants this user passwordless sudo for the exact commands
# build_ubuntu.sh's steps run as root - not a bare NOPASSWD on apt-get
# (or any other binary) with unrestricted arguments, since several of
# these tools (tee, install, sed, rm, curl -o) are trivial root-file-write
# primitives once passwordless with no argument limits: anything running
# as this user could otherwise overwrite/read any root-owned file. Each
# alias below is scoped to the fixed destination paths and subcommands
# the scripts actually use.
#
# MAINTENANCE WARNING: this list is hand-matched to the sudo calls in
# build_ubuntu.sh and lib/*.sh. Adding a new `sudo <cmd>` to any script
# in this directory without a matching entry here will work fine when
# you run it yourself interactively (you already have full sudo), but
# will fail under the unattended cron job - it has no TTY to fall back
# to a password prompt, so `set -e` aborts the whole run at that step.
install_unattended_sudo() {
  local sudoers_file="/etc/sudoers.d/dev_box"
  local old_sudoers_file="/etc/sudoers.d/dev_box_apt"

  # This runs under sudo-rs (Ubuntu's sudo reimplementation), which - like
  # standard sudo - requires ',', ':', '=', and '\' to be backslash-escaped
  # within a command's arguments, and forbids wildcards anywhere in the
  # argument list except as the sole, trailing "match any remaining args"
  # token. Both are enforced at parse time (see the `visudo -c` below), not
  # just style preferences.
  local flatpak_arch
  flatpak_arch="$(flatpak --default-arch)"

  local rule
  rule="$(
    cat <<EOF
Cmnd_Alias DEVBOX_APT = /usr/bin/apt-get update, \\
  /usr/bin/apt-get check, \\
  /usr/bin/apt-get autoclean, \\
  /usr/bin/apt-get --yes autoremove --purge, \\
  /usr/bin/apt-get --yes install *, \\
  /usr/bin/apt-get --yes purge *, \\
  /usr/bin/env DEBIAN_FRONTEND\=noninteractive apt-get --yes -o Dpkg\:\:Options\:\:\=--force-confdef -o Dpkg\:\:Options\:\:\=--force-confold full-upgrade

Cmnd_Alias DEVBOX_SYSTEMD = /usr/bin/systemctl enable --now *, \\
  /usr/bin/systemctl disable --now *, \\
  /usr/bin/systemctl mask *

Cmnd_Alias DEVBOX_PKG_MGRS = /usr/sbin/ufw enable, \\
  /usr/sbin/ufw logging low, \\
  /usr/bin/flatpak install --system --noninteractive flathub *, \\
  /usr/bin/flatpak remote-add --if-not-exists flathub https\://flathub.org/repo/flathub.flatpakrepo, \\
  /usr/bin/snap remove --purge *, \\
  /usr/bin/pro config set apt_news\=false

Cmnd_Alias DEVBOX_WRITE = /usr/bin/tee /etc/apt/preferences.d/nosnap.pref, \\
  /usr/bin/tee /etc/apt/sources.list.d/docker.list, \\
  /usr/bin/tee /etc/cron.d/dev_box_update, \\
  /usr/bin/tee /var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/$flatpak_arch/stable/policies/policies.json, \\
  /usr/bin/tee /var/lib/flatpak/extension/org.chromium.Chromium.Extension.dotfiles/$flatpak_arch/$CHROMIUM_EXTENSION_POINT_VERSION/policies/managed/extensions.json, \\
  /usr/bin/sed -i s/ENABLED\=1/ENABLED\=0/ /etc/default/motd-news, \\
  /usr/bin/rm -rf /snap /var/lib/snapd $HOME/snap, \\
  /usr/bin/install -d -m 0755 /var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/$flatpak_arch/stable/policies, \\
  /usr/bin/install -d -m 0755 /var/lib/flatpak/extension/org.chromium.Chromium.Extension.dotfiles/$flatpak_arch/$CHROMIUM_EXTENSION_POINT_VERSION/policies/managed, \\
  /usr/bin/install -m 0755 -d /etc/apt/keyrings, \\
  /usr/bin/curl -fsSL https\://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc, \\
  /usr/bin/chmod a+r /etc/apt/keyrings/docker.asc, \\
  /usr/bin/chmod 0644 /etc/cron.d/dev_box_update, \\
  /usr/bin/usermod -aG docker $USER

Cmnd_Alias DEVBOX_SUDO_SETUP = /usr/bin/test -f $sudoers_file, \\
  /usr/bin/cat $sudoers_file, \\
  /usr/bin/test -f /etc/cron.d/dev_box_update, \\
  /usr/bin/cat /etc/cron.d/dev_box_update

$USER ALL=(root) NOPASSWD: DEVBOX_APT, DEVBOX_SYSTEMD, DEVBOX_PKG_MGRS, DEVBOX_WRITE, DEVBOX_SUDO_SETUP
EOF
  )"

  if sudo test -f "$sudoers_file" && [[ "$(sudo cat "$sudoers_file")" == "$rule" ]]; then
    return 0
  fi

  # visudo/install for writing this file are deliberately NOT in the
  # allowlist above - cron can't safely grant itself new passwordless
  # permissions it doesn't already have. If this rule ever needs to
  # change (e.g. a new sudo call added to these scripts), that only
  # takes effect the next time you run build_ubuntu.sh yourself - your
  # normal interactive sudo access covers these two calls already.
  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  echo "$rule" >"$tmp"
  sudo visudo -c -f "$tmp"
  sudo install -m 0440 -o root -g root "$tmp" "$sudoers_file"

  # Superseded by the broader rule above - remove so it's not left
  # granting its own (narrower, but now redundant) access alongside it.
  if sudo test -f "$old_sudoers_file"; then
    sudo rm -f "$old_sudoers_file"
  fi
}

# Installs a system cron.d entry that runs build_ubuntu.sh unattended, so
# the whole box - OS/asdf/security/app state - stays current without you
# having to remember to run it. Requires install_unattended_sudo to have
# run first. Edit /etc/cron.d/dev_box_update directly to change the
# schedule.
install_update_cron_job() {
  local log_dir="$HOME/.local/state"
  local log_file="$log_dir/dev_box_update.log"
  local cron_file="/etc/cron.d/dev_box_update"
  local schedule="0 6 * * *" # daily at 06:00
  local rule="$schedule $USER $DOTFILES_DIR/scripts/dev_box/build_ubuntu.sh >> $log_file 2>&1"

  mkdir -p "$log_dir"

  if sudo test -f "$cron_file" && [[ "$(sudo cat "$cron_file")" == "$rule" ]]; then
    return 0
  fi

  echo "$rule" | sudo tee "$cron_file" >/dev/null
  sudo chmod 0644 "$cron_file"
}
