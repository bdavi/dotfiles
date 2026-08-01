#!/usr/bin/env bash

######################################################################
# Herdr (official install script)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
#
# No apt package, no working npm package (the "herdr" name on the
# registry is an official but empty 0.0.0 placeholder - reserved, not
# installable), and no asdf plugin, so this uses herdr's own installer
# (https://herdr.dev/docs/install/): a POSIX sh script that resolves the
# latest release from herdr.dev/latest.json and drops a single binary in
# ~/.local/bin, no sudo needed.
######################################################################

# Installs herdr on first run, then always calls `herdr update` - the
# officially documented way to keep an install-script build current
# (distinct from just re-running install.sh, which the docs reserve for
# the initial install).
install_latest_herdr() {
  command -v herdr >/dev/null || curl -fsSL https://herdr.dev/install.sh | sh
  herdr update
}

# Prefix key (default ctrl+b, see `herdr --default-config`) - config.toml
# is live, app-owned state (see install_herdr_vim_navigation_plugin
# below), so this is appended idempotently rather than managing the whole
# file. TOML requires a [keys] table's own scalar keys (prefix) to appear
# before any [[keys.command]] array-of-tables under it - reopening [keys]
# after one has already started (as install_herdr_vim_navigation_plugin's
# blocks do) isn't valid TOML - so this inserts [keys] right before the
# first [[keys.command]] line if one already exists, rather than blindly
# appending at the end.
configure_herdr_prefix_key() {
  local config=~/.config/herdr/config.toml
  grep -qx 'prefix = "ctrl+space"' "$config" 2>/dev/null && return 0

  if grep -q '^\[\[keys\.command\]\]' "$config" 2>/dev/null; then
    awk '
      !done && /^\[\[keys\.command\]\]/ {
        print "[keys]"
        print "prefix = \"ctrl+space\""
        print ""
        done = 1
      }
      { print }
    ' "$config" >"${config}.tmp"
    mv -f "${config}.tmp" "$config"
  else
    printf '\n[keys]\nprefix = "ctrl+space"\n' >>"$config"
  fi

  herdr server reload-config 2>/dev/null || true
}

# vim-herdr-navigation (https://github.com/paulbkim-dev/vim-herdr-navigation)
# - unofficial third-party plugin, Ctrl+h/j/k/l across herdr panes and
# Vim/Neovim splits, vim-tmux-navigator ported to herdr. `herdr plugin
# install` is idempotent on its own (reinstalling just re-confirms the
# same commit), but the config.toml keybindings it needs are a manual
# step per its README - config.toml is a live, app-owned file (same
# problem as XFCE's xfconf state, see configure_xfce.sh), so this
# appends idempotently instead of managing the whole file, and only
# reloads the running server when it actually changed something.
install_herdr_vim_navigation_plugin() {
  herdr plugin install paulbkim-dev/vim-herdr-navigation -y

  local config=~/.config/herdr/config.toml
  if ! grep -q '"vim-herdr-navigation.left"' "$config" 2>/dev/null; then
    cat >>"$config" <<'EOF'

[[keys.command]]
key = "ctrl+h"
type = "plugin_action"
command = "vim-herdr-navigation.left"
description = "navigate left (vim/herdr)"

[[keys.command]]
key = "ctrl+j"
type = "plugin_action"
command = "vim-herdr-navigation.down"
description = "navigate down (vim/herdr)"

[[keys.command]]
key = "ctrl+k"
type = "plugin_action"
command = "vim-herdr-navigation.up"
description = "navigate up (vim/herdr)"

[[keys.command]]
key = "ctrl+l"
type = "plugin_action"
command = "vim-herdr-navigation.right"
description = "navigate right (vim/herdr)"
EOF
    herdr server reload-config 2>/dev/null || true
  fi
}
