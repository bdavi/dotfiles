#!/usr/bin/env bash

######################################################################
# Force-installed browser extensions (Firefox + Chromium flatpaks)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh.
#
# Both browsers are installed via flatpak (see build_ubuntu.sh), which
# sandboxes them away from the usual host enterprise-policy paths
# (/etc/firefox/policies, /etc/chromium/policies/managed). Each flatpak
# instead declares its own "extension point" that Flatpak auto-mounts
# into the sandbox from a matching directory under
# /var/lib/flatpak/extension - no `flatpak install` of anything needed,
# just the right directory layout. Details:
#   https://docs.flatpak.org/en/latest/extension.html
#   https://github.com/flathub/org.chromium.Chromium/blob/master/README.md
#
# Changes only take effect the next time each browser starts.
######################################################################

# AMO (addons.mozilla.org) extension guid -> slug. The slug is used to
# build a "latest.xpi" install URL, which always redirects to whatever
# the current version is - no need to bump this when the extension
# updates.
declare -A FIREFOX_EXTENSIONS=(
  ["vimium-c@gdh1995.cn"]="vimium-c"
  ["uBlock0@raymondhill.net"]="ublock-origin"
  ["jid1-MnnxcxisBPnSXQ@jetpack"]="privacy-badger17"
  ["keepassxc-browser@keepassxc.org"]="keepassxc-browser"
  ["gdpr@cavi.au.dk"]="consent-o-matic"
  ["{74145f27-f039-47ce-a470-a662b129930a}"]="clearurls"
  ["CookieAutoDelete@kennydo.com"]="cookie-autodelete"
  ["jid1-ZAdIEUB7XOzOJw@jetpack"]="duckduckgo-for-firefox"
  ["{DDC359D1-844A-42a7-9AA1-88A850A938A8}"]="downthemall"
  ["jid1-BoFifL9Vbdl2zQ@jetpack"]="decentraleyes"
)

# Zotero Connector isn't distributed through AMO (Mozilla's review process
# can't keep up with its release cadence), so it has no AMO slug and no
# version-agnostic "latest.xpi" redirect to build a URL from. Its guid and
# the URL template below (guessable from Zotero's own downloads: the file
# is named Zotero_Connector-<version>.xpi under /connector/firefox/release/)
# were confirmed by fetching the actual xpi.
ZOTERO_FIREFOX_GUID="zotero@chnm.gmu.edu"

# The version is scraped from a JS config blob embedded in Zotero's
# download page - there's no dedicated version endpoint.
zotero_firefox_xpi_url() {
  local version
  version="$(curl -fsSL https://www.zotero.org/download/connectors \
    | grep -oP '"firefoxVersion":"\K[^"]+')"
  echo "https://download.zotero.org/connector/firefox/release/Zotero_Connector-${version}.xpi"
}

# Chrome Web Store extension ids.
CHROMIUM_EXTENSIONS=(
  "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium C
  "ekhagklcjbdpajgpjgmbionohlpdbjgc" # Zotero Connector
  "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
)

# org.mozilla.firefox declares its "systemconfig" extension point on the
# "stable" branch (flathub's default channel for this app) - fixed, not
# something that needs to track a version.
#
# policies.json isn't extension-specific - ExtensionSettings is just one
# key in Firefox's enterprise policy schema, so any other policy (see
# https://mozilla.github.io/policy-templates/) can live in the same file.
# Homepage.URL/StartPage and NewTabPage below reproduce "Blank Page" for
# both "Homepage and new windows" and "New tabs" in about:preferences.
install_firefox_extensions() {
  local arch
  arch="$(flatpak --default-arch)"

  local dir="/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/$arch/stable/policies"
  sudo install -d -m 0755 "$dir"

  local settings="{}"
  local guid slug
  for guid in "${!FIREFOX_EXTENSIONS[@]}"; do
    slug="${FIREFOX_EXTENSIONS[$guid]}"
    settings="$(jq --arg guid "$guid" \
      --arg url "https://addons.mozilla.org/firefox/downloads/latest/$slug/latest.xpi" \
      '.[$guid] = {installation_mode: "force_installed", install_url: $url}' <<<"$settings")"
  done

  settings="$(jq --arg guid "$ZOTERO_FIREFOX_GUID" --arg url "$(zotero_firefox_xpi_url)" \
    '.[$guid] = {installation_mode: "force_installed", install_url: $url}' <<<"$settings")"

  jq -n --argjson settings "$settings" \
    '{policies: {
        ExtensionSettings: $settings,
        Homepage: {URL: "about:blank", StartPage: "homepage"},
        NewTabPage: false
      }}' \
    | sudo tee "$dir/policies.json" >/dev/null
}

# org.chromium.Chromium.Extension.<id> extension points are pinned to
# version "1" by the Chromium flatpak itself (see the README linked
# above) - an extension-point version, unrelated to Chromium's own
# version, so this only needs to change if that flatpak bumps it.
CHROMIUM_EXTENSION_POINT_VERSION=1

install_chromium_extensions() {
  local arch
  arch="$(flatpak --default-arch)"

  local dir="/var/lib/flatpak/extension/org.chromium.Chromium.Extension.dotfiles/$arch/$CHROMIUM_EXTENSION_POINT_VERSION/policies/managed"
  sudo install -d -m 0755 "$dir"

  local forcelist="[]"
  local id
  for id in "${CHROMIUM_EXTENSIONS[@]}"; do
    forcelist="$(jq --arg entry "$id;https://clients2.google.com/service/update2/crx" '. + [$entry]' <<<"$forcelist")"
  done

  jq -n --argjson forcelist "$forcelist" '{ExtensionInstallForcelist: $forcelist}' \
    | sudo tee "$dir/extensions.json" >/dev/null
}
