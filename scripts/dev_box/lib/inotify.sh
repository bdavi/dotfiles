#!/usr/bin/env bash

######################################################################
# inotify watch/instance limits
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
######################################################################

# Raises the caps on inotify watches (files a process can watch) and
# instances (processes that can hold watches). The kernel's own default
# for max_user_watches scales with RAM and is already reasonable on
# this box, but that's not guaranteed elsewhere (a lower-memory VM
# computes a much lower default), so this makes an explicit floor
# instead of relying on it. max_user_instances' default of 128 is flat,
# not RAM-scaled, and easy to exhaust once nvim, VS Code, and a handful
# of docker-compose services are all watching files at once - each
# watching *process* costs one instance, regardless of how many files
# it watches.
#
# A drop-in under sysctl.d/, not an edit to any existing file, so it's
# easy to diff/remove on its own - same reasoning as the journald.conf.d
# drop-in in lib/journald.sh. Applied live via `sysctl --system`
# (reloads every sysctl.d drop-in) - no reboot or service restart
# needed, unlike journald. Content-compared against what's already
# there so that reload only happens when something actually changed.
configure_inotify_limits() {
  local conf_dir="/etc/sysctl.d"
  local conf_file="$conf_dir/60-inotify.conf"
  local rule
  rule="$(
    cat <<'EOF'
# Max files a single process can watch (VS Code/JetBrains/webpack's
# usual fix for "ENOSPC: System limit for number of file watchers
# reached").
fs.inotify.max_user_watches=524288
# Max processes that can hold inotify watches at all - each watching
# process (editor, LSP server, docker-compose service, browser tab)
# costs one, independent of how many files it watches.
fs.inotify.max_user_instances=512
EOF
  )"

  if [[ -f "$conf_file" ]] && [[ "$(cat "$conf_file")" == "$rule" ]]; then
    return 0
  fi

  sudo install -d -m 0755 "$conf_dir"
  echo "$rule" | sudo tee "$conf_file" >/dev/null
  sudo sysctl --system >/dev/null
}
