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
source "$SCRIPT_DIR/lib/update_cron.sh"
source "$SCRIPT_DIR/lib/debloat.sh"
source "$SCRIPT_DIR/lib/configure_xfce.sh"
source "$SCRIPT_DIR/lib/docker.sh"
source "$SCRIPT_DIR/lib/browser_extensions.sh"
source "$SCRIPT_DIR/lib/default_apps.sh"
source "$SCRIPT_DIR/lib/security.sh"

require_sudo

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


######################################################################
# Install Tools
######################################################################
sudo apt-get --yes install \
  curl \
  fzf \
  git \
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
  xclip


######################################################################
# Install Apps
######################################################################
sudo apt-get --yes install \
  evince \
  filezilla \
  flameshot \
  gimp \
  keepassxc \
  libreoffice \
  nemo \
  peek \
  sakura \
  speedcrunch \
  stacer \
  qimgv \
  virtualbox \
  vlc

######################################################################
# Install Flatpack
######################################################################
install_flatpak

sudo flatpak install --system --noninteractive flathub org.mozilla.firefox
sudo flatpak install --system --noninteractive flathub org.chromium.Chromium
sudo flatpak install --system --noninteractive flathub com.github.PintaProject.Pinta
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
asdf_install_latest_elixir
asdf_cleanup_elixir
asdf_install_latest_python
asdf_cleanup_python
asdf_install_latest_pnpm
asdf_cleanup_pnpm


######################################################################
# Security
######################################################################
enable_ufw
enable_apparmor
enable_fail2ban


######################################################################
# XFCE
######################################################################
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
  configure_xfce_workspaces
fi


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
