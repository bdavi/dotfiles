#!/usr/bin/env bash

######################################################################
# System-wide default application selection
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh.
######################################################################

# Sets flatpak Firefox (installed earlier, see build_ubuntu.sh) as the
# default browser on XFCE (Xubuntu). Two separate registrations, because
# different callers check different places:
#
#   - Thunar, the panel, and anything else going through exo-open reads
#     the XFCE helper written below instead of a .desktop file directly.
#   - Anything that checks mimeapps.list itself instead doesn't know
#     XFCE helpers exist, so it needs xdg-mime pointed at a real
#     .desktop file. xfce4-web-browser.desktop (shipped by xubuntu-desktop)
#     fits that role even though its own Exec doesn't launch a browser
#     directly - it just runs `exo-open --launch WebBrowser`, which reads
#     the helper below in turn, so both paths end up at the same place.
#
# Idempotent: safe to re-run as part of unattended updates.
configure_default_browser() {
  local flatpak_app_id="org.mozilla.firefox"
  local helper_id="firefox-flatpak"
  local helper_dir="$HOME/.local/share/xfce4/helpers"
  local helper_file="$helper_dir/${helper_id}.desktop"
  local helpers_rc="$HOME/.config/xfce4/helpers.rc"
  local xfce_browser_desktop="xfce4-web-browser.desktop"

  mkdir -p "$helper_dir"
  cat >"$helper_file" <<EOF
[Desktop Entry]
Version=1.0
Type=X-XFCE-Helper
X-XFCE-Category=WebBrowser
X-XFCE-Commands=flatpak run $flatpak_app_id
X-XFCE-CommandsWithParameter=flatpak run $flatpak_app_id "%s"
Exec=flatpak run $flatpak_app_id %u
Terminal=false
Icon=$flatpak_app_id
StartupNotify=true
Name=Firefox
GenericName=Web Browser
EOF

  mkdir -p "$(dirname "$helpers_rc")"
  touch "$helpers_rc"
  if grep -q '^WebBrowser=' "$helpers_rc"; then
    sed -i "s/^WebBrowser=.*/WebBrowser=${helper_id}/" "$helpers_rc"
  else
    echo "WebBrowser=${helper_id}" >>"$helpers_rc"
  fi

  xdg-mime default "$xfce_browser_desktop" x-scheme-handler/http
  xdg-mime default "$xfce_browser_desktop" x-scheme-handler/https
  xdg-mime default "$xfce_browser_desktop" text/html
}
