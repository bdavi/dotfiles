#!/usr/bin/env bash

######################################################################
# Local security scanners with no apt/npm/asdf install path
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh and github.sh.
#
# osv-scanner and bearer have no Ubuntu package, no legitimate npm
# package (the npm registry names are unclaimed/squatted), and no
# working asdf plugin, so both are installed by downloading the GitHub
# release straight to ~/.local/bin - the same approach install_asdf
# (asdf_util.sh) uses to bootstrap asdf itself. Each release publishes
# a checksums file, verified before install.
#
# semgrep is in the same boat (no apt/npm, and its one asdf plugin is
# abandoned and capped below current versions - see
# install_latest_semgrep below), but ships no standalone release
# binary either; pipx is its own supported install path.
######################################################################

######################################################################
# osv-scanner
######################################################################
install_latest_osv_scanner() {
  local latest
  latest="$(github_latest_release google/osv-scanner 2)"

  if [[ -z "$latest" ]]; then
    echo "Could not resolve latest osv-scanner v2 release" >&2
    exit 1
  fi

  local latest_version="${latest#v}"

  local installed=""
  if command -v osv-scanner >/dev/null; then
    installed="$(osv-scanner --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
  fi

  if [[ "$installed" == "$latest_version" ]]; then
    echo "osv-scanner $latest_version already installed"
    return 0
  fi

  local arch
  arch="$(release_arch)"

  local base_url="https://github.com/google/osv-scanner/releases/download/${latest}"
  local asset="osv-scanner_linux_${arch}"

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  curl -fsSL "${base_url}/${asset}" -o "$tmp/${asset}"
  curl -fsSL "${base_url}/osv-scanner_SHA256SUMS" -o "$tmp/SHA256SUMS"
  (cd "$tmp" && grep "  ${asset}\$" SHA256SUMS | sha256sum -c -)

  mkdir -p ~/.local/bin
  install -m 755 "$tmp/${asset}" ~/.local/bin/osv-scanner

  echo "Installed osv-scanner $latest_version to ~/.local/bin/osv-scanner"
}

######################################################################
# Bearer
######################################################################
# Bearer also offers an official apt repo (apt.fury.io), but it's
# configured "Trusted: yes" - unsigned, no GPG verification - so this
# downloads the release archive over HTTPS from GitHub instead, same as
# osv-scanner above.
install_latest_bearer() {
  local latest
  latest="$(github_latest_release Bearer/bearer 2)"

  if [[ -z "$latest" ]]; then
    echo "Could not resolve latest bearer v2 release" >&2
    exit 1
  fi

  local latest_version="${latest#v}"

  local installed=""
  if command -v bearer >/dev/null; then
    installed="$(bearer version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
  fi

  if [[ "$installed" == "$latest_version" ]]; then
    echo "bearer $latest_version already installed"
    return 0
  fi

  local arch
  arch="$(release_arch)"

  local base_url="https://github.com/Bearer/bearer/releases/download/${latest}"
  local asset="bearer_${latest_version}_linux_${arch}.tar.gz"

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  curl -fsSL "${base_url}/${asset}" -o "$tmp/${asset}"
  curl -fsSL "${base_url}/checksums.txt" -o "$tmp/checksums.txt"
  (cd "$tmp" && grep "  ${asset}\$" checksums.txt | sha256sum -c -)

  tar -xzf "$tmp/${asset}" -C "$tmp"

  mkdir -p ~/.local/bin
  install -m 755 "$tmp/bearer" ~/.local/bin/bearer

  echo "Installed bearer $latest_version to ~/.local/bin/bearer"
}

######################################################################
# semgrep (via pipx)
######################################################################
# No apt package, and the npm package named "semgrep" is unrelated to
# the real tool. An asdf plugin exists
# (brentjanderson/asdf-semgrep), but it's been abandoned since 2021 and
# hardcodes a version filter that rejects anything v3.3+, so it can
# never install a current semgrep - not usable. semgrep ships no
# standalone release binary either (pip/pipx, Homebrew, or Docker
# only), so this uses pipx, its own supported install path.
install_latest_semgrep() {
  sudo apt-get --yes install pipx

  if pipx list --short 2>/dev/null | cut -d' ' -f1 | grep -qx semgrep; then
    pipx upgrade semgrep
  else
    pipx install semgrep
  fi
}
