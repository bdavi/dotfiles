#!/usr/bin/env bash

######################################################################
# systemd-journald log size limits
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
######################################################################

# Caps persistent journal storage so it can't grow unbounded. Left
# unset, journald defaults to up to 10% of the filesystem it's stored
# on (with a 15% keep-free floor) - far more than a workstation ever
# needs to keep around. A drop-in under journald.conf.d/, not an edit
# to the package-owned journald.conf itself, so it survives package
# upgrades and is easy to diff/remove on its own. Content-compared
# against what's already there so the restart (which briefly
# interrupts logging) only happens when something actually changed.
configure_journald_limits() {
  local conf_dir="/etc/systemd/journald.conf.d"
  local conf_file="$conf_dir/size-limit.conf"
  local rule
  rule="$(
    cat <<'EOF'
[Journal]
# Hard cap on total persistent journal storage. Unset, journald
# defaults to up to 10% of the filesystem it's stored on (with a 15%
# keep-free floor) - far more than a workstation needs to keep around.
SystemMaxUse=500M
# Size of each individual rotated file - keeps ~10 files under the cap
# above instead of one unwieldy 500M file to grep through.
SystemMaxFileSize=50M
# Age-based backstop independent of size - nothing older than this
# sticks around even if SystemMaxUse is never reached.
MaxRetentionSec=30day
EOF
  )"

  # No sudo needed to read it back - unlike e.g. the 0440 sudoers.d drop-in
  # in lib/update_cron.sh, journald.conf.d/ and its contents are world-
  # readable (0755/0644), same as any other /etc config file.
  if [[ -f "$conf_file" ]] && [[ "$(cat "$conf_file")" == "$rule" ]]; then
    return 0
  fi

  sudo install -d -m 0755 "$conf_dir"
  echo "$rule" | sudo tee "$conf_file" >/dev/null
  sudo systemctl restart systemd-journald
}
