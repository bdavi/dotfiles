#!/usr/bin/env bash

#############################################################################
# Update pinned, GitHub-release-distributed dev tools
#############################################################################
# Companion to build_ubuntu.sh. Safe to re-run any time - each section below
# resolves the latest release within a pinned major version and reinstalls
# only if that's newer than what's on disk. build_ubuntu.sh calls this for
# its first-time install too, since "install" and "update" are the same
# operation for a single pinned-version binary.
#
# Add new tools here as they come up, following the same pattern: pin a
# major version, resolve the latest matching release via
# util.sh:github_latest_release, skip if already current.
#############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/util.sh"

#############################################################################
# asdf
#############################################################################
# Pinned to major version 0 - asdf hasn't cut a v1 yet, but when it does we
# want to review what changed before jumping, not auto-upgrade into it.
asdf_major_version=0
asdf_latest="$(github_latest_release asdf-vm/asdf "$asdf_major_version")"

if [[ -z "$asdf_latest" ]]; then
  echo "Could not resolve latest asdf v${asdf_major_version} release" >&2
  exit 1
fi

asdf_installed=""
if command -v asdf >/dev/null; then
  asdf_installed="$(asdf version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
fi

if [[ "$asdf_installed" == "$asdf_latest" ]]; then
  echo "asdf $asdf_latest already installed"
else
  asdf_arch="$(release_arch)"

  asdf_tmp="$(mktemp -d)"
  trap 'rm -rf "$asdf_tmp"' EXIT

  curl -fsSL \
    "https://github.com/asdf-vm/asdf/releases/download/${asdf_latest}/asdf-${asdf_latest}-linux-${asdf_arch}.tar.gz" \
    -o "$asdf_tmp/asdf.tar.gz"

  tar -xzf "$asdf_tmp/asdf.tar.gz" -C "$asdf_tmp"

  mkdir -p ~/.local/bin
  install -m 755 "$asdf_tmp/asdf" ~/.local/bin/asdf

  echo "Installed asdf $asdf_latest to ~/.local/bin/asdf (was: ${asdf_installed:-not installed})"
fi
