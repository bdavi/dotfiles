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
#
# config.toml itself (prefix key, theme, vim-herdr-navigation
# keybindings) isn't managed here - unlike XFCE's xfconf state, herdr
# only *reads* config.toml; the one thing that writes to it
# (first-run onboarding) is permanently skipped by setting
# onboarding = false, so it's safe to track and symlink normally, same
# as .vimrc. See config_files/.config/herdr/config.toml.
######################################################################

# Installs herdr on first run, then always calls `herdr update` - the
# officially documented way to keep an install-script build current
# (distinct from just re-running install.sh, which the docs reserve for
# the initial install).
#
# `herdr update` replaces the running binary out from under the herdr
# process managing the current session, which fails when this script is
# itself run from inside a herdr pane (the same thing --handoff exists
# for, per `herdr update --help` - not used here, we just skip). $HERDR_ENV
# is set for any shell running inside herdr, same signal .vimrc/.commonrc
# key off via $HERDR_PANE_ID/$HERDR_WORKSPACE_ID. Skipped rather than left
# to fail (which would trip set -e and take the rest of the build down
# with it) - the next run from outside a herdr session (e.g. the
# unattended cron job) picks the update back up.
install_latest_herdr() {
  command -v herdr >/dev/null || curl -fsSL https://herdr.dev/install.sh | sh

  if [[ -n "${HERDR_ENV:-}" ]]; then
    echo "Running inside herdr - skipping herdr update"
    return 0
  fi

  herdr update
}

# vim-herdr-navigation (https://github.com/paulbkim-dev/vim-herdr-navigation)
# - unofficial third-party plugin, Ctrl+h/j/k/l across herdr panes and
# Vim/Neovim splits, vim-tmux-navigator ported to herdr. Idempotent on its
# own - reinstalling just re-confirms the same commit. The keybindings it
# needs live in config_files/.config/herdr/config.toml, not here.
install_herdr_vim_navigation_plugin() {
  herdr plugin install paulbkim-dev/vim-herdr-navigation -y
}

# spaces-pr-status (https://github.com/jmarbutt/herdr-spaces-pr-status) -
# unofficial third-party plugin, shows GitHub PR status (checks/review/
# merged) on herdr spaces plus a PR board. Needs herdr >= 0.7.4, `gh`
# authenticated (shells out to it), and Node >= 20 - all pre-existing
# requirements of this dev box, so not re-checked here. Idempotent on its
# own, same as vim-herdr-navigation above. The required
# [ui.sidebar.spaces] rows live in config_files/.config/herdr/config.toml,
# not here - without them the plugin computes status but has nowhere to
# render it.
install_herdr_spaces_pr_status_plugin() {
  herdr plugin install jmarbutt/herdr-spaces-pr-status -y
}

# gitview (https://github.com/ChmaraX/herdr-gitview) - unofficial
# third-party plugin, git status/diff panel with in-place nvim editing,
# stage/commit/discard, and commit history. Ships prebuilt Rust binaries
# for macOS/Linux, so the plugin's own [[build]] step just downloads one -
# no toolchain needed here. Needs herdr >= 0.7.0 (>= 0.7.4 for native
# floating dialogs), git, and nvim - all already present on this dev box.
# Idempotent on its own, same as the other herdr_install_* functions. The
# cmd+g toggle keybinding lives in config_files/.config/herdr/config.toml,
# not here.
install_herdr_gitview_plugin() {
  herdr plugin install ChmaraX/herdr-gitview -y
}
