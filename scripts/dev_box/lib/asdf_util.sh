#!/usr/bin/env bash

################################################################################
# asdf install/update helpers
################################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh and
# update_ubuntu.sh, after util.sh.
################################################################################

# Pinned to major version 0 - asdf hasn't cut a v1 yet, but when it does we
# want to review what changed before jumping, not auto-upgrade into it.
ASDF_MAJOR_VERSION=0

# Installs (or upgrades to) the latest asdf release within
# ASDF_MAJOR_VERSION, skipping the download if that's already installed.
install_asdf() {
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

# Uninstalls all but the N most recent installed versions of an
# asdf-managed tool (default 2), so old compiled versions don't sit around
# taking up space. `asdf list` reads installed versions off disk in
# filename order (lexical, not version-aware - "10.0.0" would sort before
# "9.0.0"), so this re-sorts with `sort -V` before deciding what's oldest.
# Never uninstalls the currently active version, even if it somehow fell
# outside the keep window.
asdf_cleanup_old_versions() {
  local name="$1"
  local keep="${2:-2}"

  local current
  current="$(asdf current "$name" 2>/dev/null | tail -n1 | awk '{print $2}')"

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
    asdf uninstall "$name" "$version"
    echo "Uninstalled $name $version"
  done < <(head -n "$((total - keep))" <<<"$versions")
}
