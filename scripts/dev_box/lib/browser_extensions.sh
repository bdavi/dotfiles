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
)

# Chrome Web Store extension ids.
CHROMIUM_EXTENSIONS=(
  "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium C
)

# org.mozilla.firefox declares its "systemconfig" extension point on the
# "stable" branch (flathub's default channel for this app) - fixed, not
# something that needs to track a version.
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

  jq -n --argjson settings "$settings" '{policies: {ExtensionSettings: $settings}}' \
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
