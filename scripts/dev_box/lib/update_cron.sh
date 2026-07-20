#!/usr/bin/env bash

################################################################################
# Unattended ubuntu_maintenance.sh cron setup
################################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh
# (needs DOTFILES_DIR).
################################################################################

# Grants this user passwordless sudo for apt-get specifically (not ALL),
# so ubuntu_maintenance.sh can run unattended via cron, which has no TTY to
# prompt on. Deliberately scoped to apt-get, not broader, to keep the
# passwordless surface small - though note this still lets anything
# running as this user install/remove packages as root without a
# password, which is the accepted tradeoff for any unattended apt usage.
install_unattended_apt_sudo() {
  local rule="$USER ALL=(root) NOPASSWD: /usr/bin/apt-get"
  local sudoers_file="/etc/sudoers.d/dev_box_apt"

  if sudo test -f "$sudoers_file" && [[ "$(sudo cat "$sudoers_file")" == "$rule" ]]; then
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  echo "$rule" >"$tmp"
  sudo visudo -c -f "$tmp"
  sudo install -m 0440 -o root -g root "$tmp" "$sudoers_file"
}

# Installs a system cron.d entry that runs ubuntu_maintenance.sh unattended, so
# OS packages and asdf-managed languages stay current without you having
# to remember to run it. Requires install_unattended_apt_sudo to have run
# first. Edit /etc/cron.d/dev_box_update directly to change the schedule.
install_update_cron_job() {
  local log_dir="$HOME/.local/state"
  local log_file="$log_dir/dev_box_update.log"
  local cron_file="/etc/cron.d/dev_box_update"
  local schedule="0 6 * * *" # daily at 06:00
  local rule="$schedule $USER $DOTFILES_DIR/scripts/dev_box/ubuntu_maintenance.sh >> $log_file 2>&1"

  mkdir -p "$log_dir"

  if sudo test -f "$cron_file" && [[ "$(sudo cat "$cron_file")" == "$rule" ]]; then
    return 0
  fi

  echo "$rule" | sudo tee "$cron_file" >/dev/null
  sudo chmod 0644 "$cron_file"
}
