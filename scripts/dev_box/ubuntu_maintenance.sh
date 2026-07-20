#!/usr/bin/env bash

######################################################################
# Update pinned, GitHub-release-distributed dev tools
######################################################################
# Safe to re-run any time - each call below resolves the latest release
# within a pinned major version and reinstalls only if that's newer than
# what's on disk. See lib/ for the install functions and version pins.
#
# Add new tools here as they come up, following the same pattern: pin a
# major version, resolve the latest matching release via
# lib/github.sh:github_latest_release, skip if already current.
######################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/util.sh"
source "$SCRIPT_DIR/lib/github.sh"
source "$SCRIPT_DIR/lib/asdf_util.sh"
source "$SCRIPT_DIR/lib/asdf_langs.sh"

# Build deps for the languages below are installed via apt, so this needs
# sudo - asdf itself doesn't (installs to ~/.local/bin).
require_sudo

update_os_packages
clean_os_packages

install_asdf

asdf_install_latest_ruby
asdf_cleanup_ruby

asdf_install_latest_nodejs
asdf_cleanup_nodejs

asdf_install_latest_elixir
asdf_cleanup_elixir

asdf_install_latest_python
asdf_cleanup_python
