#!/usr/bin/env bash

######################################################################
# Ubuntu debloat: telemetry off, snap removed, flatpak in its place
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh.
#
# Deliberately excludes anything GNOME-specific (vanilla GNOME session,
# gsettings-based theming, appindicator extensions, etc.) - this box runs
# XFCE, and there's no direct XFCE equivalent worth building for most of
# it.
######################################################################

# Disables Canonical/Ubuntu telemetry, crash reporting, and nagging.
# Everything here is guarded, since most of these packages aren't
# installed on a minimal Xubuntu image anyway (they come from the
# ubuntu-desktop metapackage, which this box never had) - safe to run
# either way.
disable_telemetry() {
  # apport generates crash reports (and the "send to Canonical?" popup);
  # whoopsie is the daemon that actually uploads them.
  if dpkg -l apport 2>/dev/null | grep -q '^ii'; then
    sudo apt-get --yes purge apport apport-gtk apport-core-dump-handler \
      apport-symptoms python3-apport
  fi

  if dpkg -l whoopsie 2>/dev/null | grep -q '^ii'; then
    sudo systemctl disable --now whoopsie 2>/dev/null
    sudo apt-get --yes purge whoopsie
  fi

  # One-time anonymous system info report, sent right after install.
  if command -v ubuntu-report >/dev/null; then
    ubuntu-report send no 2>/dev/null
    sudo apt-get --yes purge ubuntu-report
  fi

  # Promotional "news" fetched from Canonical into every new terminal.
  if [[ -f /etc/default/motd-news ]]; then
    sudo sed -i 's/ENABLED=1/ENABLED=0/' /etc/default/motd-news
  fi

  # Ubuntu Pro subscription upsell nagging. Leaves ubuntu-pro-client
  # itself in place (other things may depend on it, and it's not what's
  # actually nagging you) - just the apt news hook and the desktop popup
  # daemon.
  if command -v pro >/dev/null; then
    sudo pro config set apt_news=false
  fi

  if dpkg -l ubuntu-advantage-desktop-daemon 2>/dev/null | grep -q '^ii'; then
    sudo apt-get --yes purge ubuntu-advantage-desktop-daemon
  fi
}

# Purges snapd and everything snap-related. Snaps can depend on other
# snaps (an app on a content/base snap), so a single removal pass can
# leave some behind - retries a few times, same problem the reference
# script (polhdez/ubuntu-debullshit) solves with its own retry loop.
# Pins snapd out of apt afterward so it can't silently come back as some
# other package's dependency later (this is how e.g. `apt install
# firefox` ends up reinstalling it on stock Ubuntu).
remove_snap() {
  if ! command -v snap >/dev/null; then
    return 0
  fi

  local pkgs pkg
  for _ in 1 2 3 4 5; do
    pkgs="$(snap list 2>/dev/null | tail -n +2 | awk '{print $1}')"
    [[ -z "$pkgs" ]] && break

    while IFS= read -r pkg; do
      sudo snap remove --purge "$pkg" 2>/dev/null || true
    done <<<"$pkgs"
  done

  # firefox/chromium-browser are apt transitional packages whose entire
  # job is installing the snap - meaningless (and left broken) once
  # snapd's gone, so they go too - replaced by the flatpak installs in
  # build_ubuntu.sh's Flatpak section.
  # Purged individually (not `purge firefox chromium-browser` in one
  # call) since apt-get purge hard-fails on an unrecognized package name,
  # not just a not-installed one - keeps one going missing from ever
  # aborting the other's removal.
  if dpkg -l firefox 2>/dev/null | grep -q '^ii'; then
    sudo apt-get --yes purge firefox
  fi

  if dpkg -l chromium-browser 2>/dev/null | grep -q '^ii'; then
    sudo apt-get --yes purge chromium-browser
  fi

  sudo systemctl disable --now snapd.socket snapd.service 2>/dev/null || true
  sudo systemctl mask snapd.service 2>/dev/null || true

  sudo apt-get --yes purge snapd
  sudo rm -rf /snap /var/lib/snapd "$HOME/snap"

  printf 'Package: snap*\nPin: release a=*\nPin-Priority: -10\n' \
    | sudo tee /etc/apt/preferences.d/nosnap.pref >/dev/null
}

# Installs flatpak and adds the flathub remote. CLI-only, deliberately -
# no GNOME Software or other GUI store bundled.
install_flatpak() {
  sudo apt-get --yes install flatpak
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}
