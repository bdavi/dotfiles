#!/usr/bin/env bash

######################################################################
# Playwright (via npm)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh and asdf_langs.sh (needs node/npm on PATH already).
#
# No apt package; playwright is a real, Microsoft-maintained npm
# package, so this uses the npm fallback tier directly - no asdf plugin
# needed.
######################################################################

# Installs (or upgrades to) the latest playwright CLI globally via npm,
# then (re)syncs the browser binaries and their apt-level dependencies
# (libnss3, libatk, etc.) to match - `playwright install --with-deps`
# is a no-op when both are already current, so this is safe to re-run
# even when the npm install step above was skipped.
install_latest_playwright() {
  local latest
  latest="$(npm view playwright version)"

  local installed
  installed="$(npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies.playwright.version // empty')"

  if [[ "$installed" == "$latest" ]]; then
    echo "playwright $latest already installed"
  else
    npm install -g "playwright@${latest}"
  fi

  playwright install --with-deps
}
