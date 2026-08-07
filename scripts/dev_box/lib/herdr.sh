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
# keybindings) isn't managed here - herdr mostly just *reads* config.toml,
# and the two things that write to it are both settled: first-run
# onboarding is permanently skipped by setting onboarding = false, and
# `herdr channel set` writes an [update] channel block (discovered
# 2026-08-06 when switch_herdr_to_preview_channel ran) - that block is now
# tracked in the repo copy, so the switch is a no-op on any box built from
# these dotfiles and nothing rewrites the file day to day. Safe to track
# and symlink normally, same as .vimrc. See
# config_files/.config/herdr/config.toml.
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
#
# Must run before switch_herdr_to_preview_channel below - on a genuinely
# fresh box there's no herdr binary yet for `herdr channel` to run
# against, and this is the function that installs one.
install_latest_herdr() {
  command -v herdr >/dev/null || curl -fsSL https://herdr.dev/install.sh | sh

  if [[ -n "${HERDR_ENV:-}" ]]; then
    echo "Running inside herdr - skipping herdr update"
    return 0
  fi

  herdr update
}

# herdr-mirror (nikok6/herdr-mirror, installed below) needs both ends of
# the mirror connection on herdr's preview channel - specifically a
# preview build dated 2026-06-30 or newer, per the plugin's own README
# (see ../../../misc/herdr_codespaces.md for the full verification). This
# switches the channel and re-runs `herdr update` so the binary actually
# matches - `channel set` alone only changes which channel *future*
# updates pull from, it doesn't itself fetch anything.
#
# Same $HERDR_ENV skip as install_latest_herdr, for the same reason -
# only the update half needs to skip; the channel switch itself doesn't
# touch the running binary and is safe to always run.
switch_herdr_to_preview_channel() {
  local current
  current="$(herdr channel show)"

  if [[ "$current" == "preview" ]]; then
    echo "herdr already on preview channel ($(herdr --version))"
    return 0
  fi

  echo "Switching herdr from $current to preview channel"
  herdr channel set preview

  if [[ -n "${HERDR_ENV:-}" ]]; then
    echo "Running inside herdr - skipping herdr update (re-run the build outside a herdr pane to actually pick up a preview build)"
    return 0
  fi

  herdr update
  echo "herdr now on preview channel: $(herdr --version)"
  echo "herdr-mirror needs a preview build dated 2026-06-30 or newer - if the plugin ever reports a version/compatibility mismatch, check that date against this version"
}

# herdr-mirror (https://github.com/nikok6/herdr-mirror) - unofficial
# third-party plugin, mirrors several remote herdr servers' workspaces into
# the local sidebar simultaneously (prefixed "<host>: <name>"), unlike core
# herdr's own `--remote` which attaches to one remote 1:1 and replaces the
# local view. Needs herdr on the preview channel (see
# switch_herdr_to_preview_channel above) - install this after that function
# has run, not before. The remote side (each Codespace) needs no plugin,
# just herdr itself - see comoto-codespaces-dotfiles/script/setup. Its own
# config - ~/.config/herdr-mirror/hosts.toml, a non-standard location the
# plugin's README specifies directly rather than the usual
# `herdr plugin config-dir` path other plugins use - is managed by cs-sync
# in config_files/.workrc-codespaces, not here; that needs to re-run
# whenever the Codespace list changes, not just at build time.
#
# TEMPORARY PATCHED BUILD (2026-08-07): the released plugin (v0.1.16) has a
# rendering bug that drops the last character of every wrapped row in
# mirror panes, corrupting anything copied out of them (found live copying
# a Claude auth URL - see misc/herdr_codespaces.md). Upstream PR
# nikok6/herdr-mirror#27 fixes it but is unmerged, so until the fix ships
# in a release this builds the PR branch from source (cargo via asdf rust,
# asdf_langs.sh) and links it in place of the GitHub install. Once the fix
# is released, the same function detects that automatically, removes the
# patched build, and switches back to the normal GitHub install - at that
# point everything from HERDR_MIRROR_FIX_PR down through
# _remove_patched_herdr_mirror can be deleted and the last line restored to
# a bare `herdr plugin install`.
HERDR_MIRROR_UPSTREAM="nikok6/herdr-mirror"
HERDR_MIRROR_FIX_PR=27
HERDR_MIRROR_BROKEN_RELEASE="v0.1.16" # newest release WITHOUT the fix
HERDR_MIRROR_FORK_URL="https://github.com/finafisken/herdr-mirror.git"
HERDR_MIRROR_FIX_BRANCH="fix/full-width-row-el"
HERDR_MIRROR_LOCAL_DIR="$HOME/code/herdr-mirror"

# True once upstream has both merged PR #27 and cut a release newer than
# the known-broken one (merge alone isn't enough - `herdr plugin install`
# fetches the latest *release* binary, which would still be broken until a
# new one is tagged). Network/API failures return false, i.e. "keep
# whatever is installed now" - the safe answer for the unattended cron run.
_herdr_mirror_fix_released() {
  local merged latest
  merged="$(gh api "repos/${HERDR_MIRROR_UPSTREAM}/pulls/${HERDR_MIRROR_FIX_PR}" --jq .merged 2>/dev/null)" || return 1
  [[ "$merged" == "true" ]] || return 1

  latest="$(github_latest_release "$HERDR_MIRROR_UPSTREAM" 0)"
  [[ -n "$latest" && "$latest" != "$HERDR_MIRROR_BROKEN_RELEASE" ]] || return 1
  [[ "$(printf '%s\n%s\n' "$HERDR_MIRROR_BROKEN_RELEASE" "$latest" | sort -V | tail -n1)" == "$latest" ]]
}

# Clones/updates the PR branch at HERDR_MIRROR_LOCAL_DIR, rebuilds when the
# checkout changed (or the binary is missing), and links it as the mirror
# plugin. Idempotent: an up-to-date, already-linked build is a no-op.
_ensure_patched_herdr_mirror() {
  if ! command -v cargo >/dev/null; then
    echo "herdr-mirror: cargo not found - asdf_install_latest_rust (asdf_langs.sh) must run before this" >&2
    return 1
  fi

  if [[ ! -d "$HERDR_MIRROR_LOCAL_DIR" ]]; then
    git clone --branch "$HERDR_MIRROR_FIX_BRANCH" "$HERDR_MIRROR_FORK_URL" \
      "$HERDR_MIRROR_LOCAL_DIR" || return 1
  fi

  local before after
  before="$(git -C "$HERDR_MIRROR_LOCAL_DIR" rev-parse HEAD)"
  # Offline/pull failure isn't fatal - build whatever is checked out.
  git -C "$HERDR_MIRROR_LOCAL_DIR" pull --ff-only 2>/dev/null \
    || echo "herdr-mirror: git pull failed (offline?), building the existing checkout"
  after="$(git -C "$HERDR_MIRROR_LOCAL_DIR" rev-parse HEAD)"

  local bin="$HERDR_MIRROR_LOCAL_DIR/target/release/herdr-mirror"
  if [[ ! -x "$bin" || "$before" != "$after" ]]; then
    (cd "$HERDR_MIRROR_LOCAL_DIR" && cargo build --release) || return 1
    echo "herdr-mirror: built patched plugin at $after"
    # A running mirror daemon keeps executing the old binary - restart it
    # if the local herdr server is up (best-effort; harmless when it isn't:
    # the next daemon start uses the new binary anyway).
    if herdr status >/dev/null 2>&1; then
      herdr plugin action invoke teardown --plugin mirror >/dev/null 2>&1 || true
      herdr plugin action invoke start --plugin mirror >/dev/null 2>&1 || true
    fi
  fi

  if herdr plugin list 2>/dev/null | grep -q "local:${HERDR_MIRROR_LOCAL_DIR}"; then
    echo "herdr-mirror: patched build already linked (upstream PR #${HERDR_MIRROR_FIX_PR} still unreleased)"
    return 0
  fi

  # A GitHub-installed copy occupies the same plugin id - remove it first.
  if herdr plugin list 2>/dev/null | grep -q "github:${HERDR_MIRROR_UPSTREAM}"; then
    herdr plugin uninstall mirror
  fi
  herdr plugin link "$HERDR_MIRROR_LOCAL_DIR" --enabled >/dev/null
  echo "herdr-mirror: linked patched build from $HERDR_MIRROR_LOCAL_DIR"
}

# Unlinks the patched build and deletes its clone - only if the directory
# really is our clone of the fix fork, never someone's unrelated checkout.
_remove_patched_herdr_mirror() {
  if herdr plugin list 2>/dev/null | grep -q "local:${HERDR_MIRROR_LOCAL_DIR}"; then
    herdr plugin unlink mirror
  fi
  if [[ -d "$HERDR_MIRROR_LOCAL_DIR" ]] \
    && [[ "$(git -C "$HERDR_MIRROR_LOCAL_DIR" remote get-url origin 2>/dev/null)" == "$HERDR_MIRROR_FORK_URL" ]]; then
    rm -rf "$HERDR_MIRROR_LOCAL_DIR"
    echo "herdr-mirror: removed patched build clone at $HERDR_MIRROR_LOCAL_DIR"
  fi
}

install_herdr_mirror_plugin() {
  if _herdr_mirror_fix_released; then
    if herdr plugin list 2>/dev/null | grep -q "local:${HERDR_MIRROR_LOCAL_DIR}"; then
      echo "herdr-mirror: upstream PR #${HERDR_MIRROR_FIX_PR} fix is released - switching from the patched build to the GitHub install"
      _remove_patched_herdr_mirror
    fi
    herdr plugin install "$HERDR_MIRROR_UPSTREAM" --yes
    return
  fi
  _ensure_patched_herdr_mirror
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

# reviewr (https://github.com/persiyanov/herdr-reviewr) - unofficial
# third-party plugin, review panel for an agent's diff (comment, send
# feedback back) plus a read-only PR/checks/comments view - complements
# gitview above, which is edit/stage/commit focused, not review focused.
# Needs herdr >= 0.7.5, git, and (for the PR tab) an authenticated `gh` -
# all already present on this dev box. Idempotent on its own, same as the
# other install_herdr_*_plugin functions. Its own settings (theme,
# base_branches, default_scope, ...) live in a separate file reviewr owns -
# ~/.config/herdr/plugins/config/persiyanov.reviewr/config.toml, unrelated
# to config.toml's [keys]/[theme]/etc - toggle_placement set to "tab"
# there. The prefix+r toggle keybinding (which also moves the built-in
# resize_mode off its default prefix+r onto prefix+v) lives in
# config_files/.config/herdr/config.toml, not here.
install_herdr_reviewr_plugin() {
  herdr plugin install persiyanov/herdr-reviewr -y
}
