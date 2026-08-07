#!/usr/bin/env bash

######################################################################
# Herdr + GitHub Codespaces integration
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# herdr.sh. Wires up the local machine's SSH config so `gh codespace ssh`
# aliases exist for herdr-mirror (and cs-connect/cs-remote in
# config_files/.workrc-codespaces) to target. See
# ../../../misc/herdr_codespaces.md for the full plan, verified claims,
# and decisions this depends on.
#
# Deliberately does NOT run `gh auth refresh -s codespace` here - that's
# an interactive command (opens a browser) and has no place in an
# unattended build script (this also runs from the daily cron job, see
# lib/update_cron.sh). Checked-for, not run: the build logs clear
# instructions and moves on rather than hanging on a prompt that will
# never be answered non-interactively.
#
# Also deliberately does NOT run cs-sync (the ~/.ssh/codespaces + herdr-
# mirror hosts.toml generation) - that needs to re-run every time the
# Codespace list changes, not just at build time, so it lives as an
# on-demand function in config_files/.workrc-codespaces instead.
######################################################################

# `gh codespace ssh --config`/herdr-mirror's SSH transport both need the
# 'codespace' OAuth scope, which the default `gh auth login` token doesn't
# include. Non-fatal (returns 1, doesn't exit) - a missing scope shouldn't
# take down the rest of an otherwise-unrelated build.
ensure_gh_codespace_scope() {
  if gh auth status 2>&1 | grep -q "'codespace'"; then
    echo "gh auth already has the codespace scope"
    return 0
  fi

  echo "gh auth is missing the 'codespace' scope, required for Codespaces SSH (cs-connect/cs-remote, herdr-mirror)."
  echo "Run this yourself, then re-run the build:"
  echo "  gh auth refresh -h github.com -s codespace"
  return 1
}

# `gh codespace ssh --config` generates per-Codespace SSH host aliases;
# cs-sync (config_files/.workrc-codespaces) regenerates that file on
# demand, but it only works if ~/.ssh/config actually includes it. This is
# the one-time wiring for that - idempotent via the grep-before-append
# check, the same idiom lib/default_apps.sh uses for editing
# ~/.config/xfce4/helpers.rc outside this repo's usual symlink management.
ensure_ssh_config_includes_codespaces() {
  local ssh_config="$HOME/.ssh/config"
  local include_line="Include ~/.ssh/codespaces"

  mkdir -p "$HOME/.ssh"
  touch "$ssh_config"

  if grep -qF "$include_line" "$ssh_config"; then
    echo "$ssh_config already includes ~/.ssh/codespaces"
    return 0
  fi

  echo "Adding codespaces Include to ~/.ssh/config"
  printf '\nMatch all\n%s\n' "$include_line" >> "$ssh_config"
}
