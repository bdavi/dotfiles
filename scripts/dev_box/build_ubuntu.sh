#!/usr/bin/env bash

######################################################################
# Xubuntu dev box: initial setup, and the daily unattended cron target
######################################################################
# Assumes a fresh install of Xubuntu using the "minimal install" option.
# Every step is idempotent, so this is also what "Unattended updates
# (cron)" below runs daily to keep the box current - same script, same
# steps, whether you're running it by hand or it's running unattended.
#
# A few one-time steps need a GUI or a manual download and can't run
# unattended - left as comments describing exactly what to do, they're
# inert otherwise. Run the rest top-to-bottom.
######################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/util.sh"
source "$SCRIPT_DIR/lib/github.sh"
source "$SCRIPT_DIR/lib/asdf_util.sh"
source "$SCRIPT_DIR/lib/asdf_langs.sh"
source "$SCRIPT_DIR/lib/playwright.sh"
source "$SCRIPT_DIR/lib/zizmor.sh"
source "$SCRIPT_DIR/lib/update_cron.sh"
source "$SCRIPT_DIR/lib/debloat.sh"
source "$SCRIPT_DIR/lib/journald.sh"
source "$SCRIPT_DIR/lib/fstrim.sh"
source "$SCRIPT_DIR/lib/inotify.sh"
source "$SCRIPT_DIR/lib/configure_xfce.sh"
source "$SCRIPT_DIR/lib/budgie_panel.sh"
source "$SCRIPT_DIR/lib/qt_scaling.sh"
source "$SCRIPT_DIR/lib/console_font.sh"
source "$SCRIPT_DIR/lib/docker.sh"
source "$SCRIPT_DIR/lib/github_cli.sh"
source "$SCRIPT_DIR/lib/vscode.sh"
source "$SCRIPT_DIR/lib/browser_extensions.sh"
source "$SCRIPT_DIR/lib/default_apps.sh"
source "$SCRIPT_DIR/lib/security.sh"
source "$SCRIPT_DIR/lib/security_scanners.sh"
source "$SCRIPT_DIR/lib/neovim.sh"
source "$SCRIPT_DIR/lib/herdr.sh"
source "$SCRIPT_DIR/lib/herdr_codespaces.sh"
source "$SCRIPT_DIR/lib/nimbalyst.sh"

require_sudo

######################################################################
# APT repo hygiene
######################################################################
# do-release-upgrade rewrites third-party repos into its own .sources
# files without Signed-By. Once install_docker's docker.list exists,
# that leaves the docker repo defined twice with different signing
# config, and every apt call - including this script's first one -
# hard-fails with "Conflicting values set for option Signed-By". Must
# run before anything touches apt.
sudo rm -f /etc/apt/sources.list.d/download_docker_com_linux_ubuntu.sources

# Same conflict, other direction: the code package's postinst maintains
# its own vscode.sources (different keyring), so install_vscode's
# bootstrap entry has to go once that exists. install_vscode cleans up
# after itself too; this covers a run that died between the two.
if [[ -f /etc/apt/sources.list.d/vscode.sources ]]; then
  sudo rm -f /etc/apt/sources.list.d/vscode.list \
    /etc/apt/keyrings/packages.microsoft.gpg
fi

######################################################################
# Updates
######################################################################
# upgrade_os_distro
update_os_packages
clean_os_packages


######################################################################
# Debloat
######################################################################
disable_telemetry
remove_snap
remove_virtualbox


######################################################################
# Journald
######################################################################
configure_journald_limits


######################################################################
# SSD TRIM
######################################################################
enable_fstrim


######################################################################
# inotify limits
######################################################################
configure_inotify_limits


######################################################################
# Install Tools
######################################################################
sudo apt-get --yes install \
  curl \
  git \
  gitleaks \
  highlight \
  jq \
  ranger \
  pandoc \
  shellcheck \
  shfmt \
  silversearcher-ag \
  tmux \
  tree \
  wget \
  wl-clipboard \
  xclip


######################################################################
# Install Apps
######################################################################
sudo apt-get --yes install \
  blueman \
  evince \
  filezilla \
  gimp \
  keepassxc \
  libreoffice \
  libspa-0.2-bluetooth \
  nemo \
  okular \
  peek \
  sakura \
  speedcrunch \
  stacer \
  qimgv \
  vlc

######################################################################
# Install Flatpack
######################################################################
install_flatpak

sudo flatpak install --system --noninteractive flathub org.mozilla.firefox
sudo flatpak install --system --noninteractive flathub org.chromium.Chromium
sudo flatpak install --system --noninteractive flathub com.github.PintaProject.Pinta
# Flatpak rather than apt: the archive still ships v13, whose capture
# overlay misplaces itself on multi-monitor Wayland (offset selections,
# "shifting" windows - the v14 release notes' headline fix is the
# per-monitor capture rework). Drop back to the apt package once it
# reaches >= 14. The remove is the v13 -> v14 migration for boxes built
# before this change; no-op elsewhere.
if pkg_installed flameshot; then
  sudo apt-get --yes remove flameshot
fi
sudo flatpak install --system --noninteractive flathub org.flameshot.Flameshot
sudo flatpak install --system --noninteractive flathub net.nokyan.Resources
sudo flatpak install --system --noninteractive flathub io.github.linx_systems.ClamUI
sudo flatpak install --system --noninteractive flathub com.slack.Slack
sudo flatpak install --system --noninteractive flathub com.tomjwatson.Emote
sudo flatpak install --system --noninteractive flathub org.gnome.baobab
sudo flatpak install --system --noninteractive flathub com.github.johnfactotum.Foliate
sudo flatpak install --system --noninteractive flathub org.kiwix.desktop

configure_default_browser

######################################################################
# Zotero
######################################################################
if ! dpkg -s zotero &>/dev/null; then
  wget -qO- https://raw.githubusercontent.com/retorquere/zotero-pkg/master/install.sh | sudo bash
  sudo apt-get update
fi
sudo apt-get --yes install zotero


######################################################################
# Balena Etcher
######################################################################
# if ! dpkg -s balena-etcher &>/dev/null; then
#   curl -1sLf 'https://dl.cloudsmith.io/public/balena/etcher/setup.deb.sh' | sudo -E bash
#   sudo apt-get update
# fi
# sudo apt-get --yes install balena-etcher


######################################################################
# Browser extensions
######################################################################
install_firefox_extensions
install_chromium_extensions


######################################################################
# Docker
######################################################################
install_docker


######################################################################
# GitHub CLI
######################################################################
install_github_cli


######################################################################
# VS Code
######################################################################
install_vscode


######################################################################
# Unattended updates (cron)
######################################################################
# Lets this same script run unattended on a schedule, reasserting
# everything below - OS/asdf updates, security hardening, app installs,
# XFCE config - not just re-running once at initial setup. Never a
# distro version upgrade (see upgrade_os_distro below for that). One-time
# setup; edit /etc/cron.d/dev_box_update directly to change the schedule.
# install_unattended_sudo
# install_update_cron_job


######################################################################
# Dotfiles
######################################################################
# MANUAL prerequisite: clone this repo before running the rest of the script
#   mkdir -p ~/code && cd ~/code
#   git clone https://github.com/bdavi/dotfiles.git
#   cd dotfiles

"$DOTFILES_DIR/scripts/install_dotfiles.sh"


######################################################################
# Vim
######################################################################
sudo apt-get --yes install vim-gtk3 # use this instead of just vim for clipboard integration

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +'PlugInstall --sync' +qa


######################################################################
# Languages (via asdf)
######################################################################
install_asdf
asdf_install_latest_ruby
asdf_cleanup_ruby
asdf_install_latest_nodejs
asdf_cleanup_nodejs
install_latest_playwright
asdf_install_latest_golang
asdf_cleanup_golang
asdf_install_latest_elixir
asdf_cleanup_elixir
asdf_install_latest_python
asdf_cleanup_python
install_latest_zizmor
asdf_install_latest_pnpm
asdf_cleanup_pnpm
asdf_install_latest_lefthook
asdf_cleanup_lefthook
asdf_install_latest_rust
asdf_cleanup_rust


######################################################################
# Neovim
######################################################################
# See lib/neovim.sh for why this needs to be more than just a `Lazy sync`.
install_neovim


######################################################################
# Security scanners
######################################################################
install_latest_osv_scanner
install_latest_bearer
install_latest_semgrep


######################################################################
# Herdr
######################################################################
install_latest_herdr
install_herdr_vim_navigation_plugin
install_herdr_spaces_pr_status_plugin
install_herdr_gitview_plugin
install_herdr_reviewr_plugin

# This dotfiles repo is shared between a personal machine and a work
# machine; ~/monorepo only exists on the work machine, so it's the same
# signal .commonrc already uses to gate .workrc/.workrc-codespaces. The
# GitHub Codespaces integration (preview channel, herdr-mirror, gh cs
# wiring) is Comoto-specific and has no reason to run anywhere else - see
# misc/herdr_codespaces.md.
if [ -d "$HOME/monorepo" ]; then
  switch_herdr_to_preview_channel
  install_herdr_mirror_plugin

  # Not fatal if the codespace scope is missing, just logs instructions
  # and moves on.
  ensure_gh_codespace_scope || true
  ensure_ssh_config_includes_codespaces
fi


######################################################################
# Nimbalyst
######################################################################
install_nimbalyst


######################################################################
# Security
######################################################################
enable_ufw
enable_apparmor
enable_fail2ban


######################################################################
# XFCE
######################################################################
# xfce4 is a no-op on Xubuntu but installs XFCE as an alternative
# session on the Budgie work box (pick it from the login screen's
# session menu). xfce4-goodies fills in the extra panel plugins and
# tools neither install ships by default. xcape powers the bare-Super
# whisker-menu tap (see configure_xfce_super_whiskermenu).
sudo apt-get --yes install xfce4 xfce4-goodies xcape

# MANUAL (one-time, per machine): configure_xfce_panel pins the panel to
# the "Primary" output, but a fresh box has no monitor flagged primary
# (the displays channel starts with no saved profile), so the panel falls
# back to the first monitor. Open Settings -> Display, arrange the
# monitors, tick "Primary" on the main one, and Apply - then also save
# the layout as a named profile (Advanced tab in the same dialog).
# Apply alone only updates the "Default" scheme, which xfsettingsd
# reasserts at session startup but NOT when a monitor connects
# mid-session - and NVIDIA PRIME outputs (HDMI-1-0 etc.) enumerate after
# the session starts, so with only "Default" the layout is lost at every
# login. A saved profile whose EDID set matches the connected monitors
# is reapplied on both startup and connect (/AutoEnableProfiles, ships
# as 3 = always). The profile can also be created headlessly by copying
# the /Default tree in the displays channel to /<name> via xfconf-query
# and pointing /ActiveProfile at it.

# Needs a running desktop session - xfconf-query talks to xfconfd over
# the session D-Bus, which doesn't exist under cron. Skipped there rather
# than left to fail (which would trip set -e), and deliberately placed
# last, after every step that matters for unattended maintenance - OS/
# asdf updates, security hardening, app installs - so a skip here can't
# take any of those down with it. Interactive runs (the desktop session
# that's running this script) always have one.
if pgrep -u "$USER" -x xfce4-session >/dev/null; then
  configure_xfce_theme
  configure_xfce_terminal
  configure_xfce_power_manager
  configure_xfce_panel
  configure_xfce_keyboard_shortcuts
  configure_xfce_super_whiskermenu
  configure_xfce_systray_watcher
  configure_xfce_workspaces
  configure_xfce_hidpi_host_overrides
  configure_xfce_ensure_panel_visible
fi

# Unlike the xfconf calls above, doesn't need a running desktop session -
# /etc/environment is read at login regardless, so this is safe (and
# useful) to run during initial box setup too.
configure_qt_scale_factor

# Same story - the virtual console exists independent of any desktop
# session, so this is safe during initial box setup too.
configure_console_font


######################################################################
# Budgie
######################################################################
# Like the two steps above, just writes files - no desktop session
# needed, safe under cron. No-op unless budgie-desktop is installed
# (the work box, Ubuntu Budgie since 26.04); the Xubuntu box skips it
# entirely. See lib/budgie_panel.sh for why this workaround exists.
configure_budgie_panel_primary_display


######################################################################
# Claude
######################################################################
# MANUAL: Claude Desktop has to be downloaded by hand (login-gated, no
# stable direct-download URL to script)
#   Download the .deb from https://claude.ai/download
#   sudo apt install ~/Downloads/claude-desktop_amd64.deb

# Claude Code CLI
# curl -fsSL https://claude.ai/install.sh | bash
# Installs to ~/.local/bin - already on PATH via config_files/.bashrc
