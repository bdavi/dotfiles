#!/usr/bin/env bash

######################################################################
# asdf install/update helpers
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh.
######################################################################

# Pinned to major version 0 - asdf hasn't cut a v1 yet, but when it does we
# want to review what changed before jumping, not auto-upgrade into it.
ASDF_MAJOR_VERSION=0

# Old asdf (pre-0.16) installed itself as a full git clone at ~/.asdf -
# bin/, lib/, completions, and the asdf.sh entry point sourced from
# .bashrc, checked directly into the same directory used for
# plugins/shims/installed tool versions. The new asdf is a single
# downloaded Go binary (installed below to ~/.local/bin) that treats
# ~/.asdf purely as a data dir, with no git repo of its own - so a
# leftover .git there means the old install is still present. Wipes the
# whole directory rather than salvaging installed plugins/versions -
# asdf_plugin_add/asdf_install_latest_global calls later in the script
# repopulate them from scratch on the new asdf.
remove_old_asdf() {
  if [[ -d ~/.asdf/.git ]]; then
    echo "Removing old git-based asdf install at ~/.asdf"
    rm -rf ~/.asdf
  fi
}

# Installs (or upgrades to) the latest asdf release within
# ASDF_MAJOR_VERSION, skipping the download if that's already installed.
install_asdf() {
  remove_old_asdf

  local latest
  latest="$(github_latest_release asdf-vm/asdf "$ASDF_MAJOR_VERSION")"

  if [[ -z "$latest" ]]; then
    echo "Could not resolve latest asdf v${ASDF_MAJOR_VERSION} release" >&2
    exit 1
  fi

  local installed=""
  if command -v asdf >/dev/null; then
    installed="$(asdf version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
  fi

  if [[ "$installed" == "$latest" ]]; then
    echo "asdf $latest already installed"
    return 0
  fi

  local arch
  arch="$(release_arch)"

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  curl -fsSL \
    "https://github.com/asdf-vm/asdf/releases/download/${latest}/asdf-${latest}-linux-${arch}.tar.gz" \
    -o "$tmp/asdf.tar.gz"

  tar -xzf "$tmp/asdf.tar.gz" -C "$tmp"

  mkdir -p ~/.local/bin
  install -m 755 "$tmp/asdf" ~/.local/bin/asdf

  echo "Installed asdf $latest to ~/.local/bin/asdf (was: ${installed:-not installed})"
}

# Idempotently adds an asdf plugin.
asdf_plugin_add() {
  local name="$1"
  local url="$2"

  asdf plugin list | grep -qx "$name" || asdf plugin add "$name" "$url"
}

# Installs the latest version of an asdf-managed tool (no-op if that
# version is already installed) and sets it as the global/home version.
asdf_install_latest_global() {
  local name="$1"

  local latest
  latest="$(asdf latest "$name")"

  asdf install "$name" "$latest"
  asdf set --home "$name" "$latest"

  echo "$name $latest set as global version"
}

# Versions of $name listed in asdf_pinned_versions.conf (one per line as
# "<tool> <version>"; blank lines and #-comments ignored) - kept installed
# by asdf_cleanup_old_versions regardless of age.
asdf_pinned_versions() {
  local name="$1"

  [[ -f "$SCRIPT_DIR/asdf_pinned_versions.conf" ]] || return 0

  awk -v tool="$name" '$1 == tool { print $2 }' "$SCRIPT_DIR/asdf_pinned_versions.conf"
}

# Uninstalls all but the N most recent installed versions of an
# asdf-managed tool (default 1, i.e. only the latest), so old compiled
# versions don't sit around taking up space. `asdf list` reads installed
# versions off disk in filename order (lexical, not version-aware -
# "10.0.0" would sort before "9.0.0"), so this re-sorts with `sort -V`
# before deciding what's oldest. Never uninstalls the currently active
# version, even if it somehow fell outside the keep window, or any version
# pinned in asdf_pinned_versions.conf.
asdf_cleanup_old_versions() {
  local name="$1"
  local keep="${2:-1}"

  local current
  current="$(asdf current "$name" 2>/dev/null | tail -n1 | awk '{print $2}')"

  local pinned
  pinned="$(asdf_pinned_versions "$name")"

  local versions
  versions="$(asdf list "$name" 2>/dev/null | sed 's/^[[:space:]*]*//' | sort -V)"

  local total
  total="$(grep -c . <<<"$versions")"

  if ((total <= keep)); then
    return 0
  fi

  local version
  while IFS= read -r version; do
    [[ -z "$version" || "$version" == "$current" ]] && continue
    grep -qxF "$version" <<<"$pinned" && continue
    asdf uninstall "$name" "$version"
    echo "Uninstalled $name $version"
  done < <(head -n "$((total - keep))" <<<"$versions")
}
