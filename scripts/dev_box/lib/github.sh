#!/usr/bin/env bash

######################################################################
# GitHub release helpers
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh and
# ubuntu_maintenance.sh, after util.sh.
######################################################################

# Latest release tag for a GitHub repo, pinned to a major version, e.g.
#   github_latest_release asdf-vm/asdf 0   ->  v0.20.0
github_latest_release() {
  local repo="$1"
  local major_version="$2"

  curl -fsSL "https://api.github.com/repos/${repo}/releases" \
    | grep -o '"tag_name": *"v[^"]*"' \
    | sed -E 's/.*"(v[^"]+)".*/\1/' \
    | grep -E "^v${major_version}\." \
    | sort -V \
    | tail -n1
}

# GitHub release asset architecture naming (amd64/arm64) for this machine.
release_arch() {
  case "$(uname -m)" in
    x86_64) echo amd64 ;;
    aarch64) echo arm64 ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      return 1
      ;;
  esac
}
