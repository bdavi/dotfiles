#!/usr/bin/env bash

################################################################################
# Xubuntu dev box bootstrap
################################################################################
# Assumes a fresh install of Xubuntu using the "minimal install" option.
#
# Not everything here can be run unattended - a few steps require a GUI or
# a manual download and are left as comments describing exactly what to do.
# Run the rest top-to-bottom.
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/util.sh"
source "$SCRIPT_DIR/lib/github.sh"
source "$SCRIPT_DIR/lib/asdf_util.sh"
source "$SCRIPT_DIR/lib/asdf_langs.sh"
source "$SCRIPT_DIR/lib/update_cron.sh"
source "$SCRIPT_DIR/lib/debloat.sh"
source "$SCRIPT_DIR/lib/configure_xfce.sh"

################################################################################
# Sudo
################################################################################
# Run as your normal user (not root) - the dotfiles/vim/fzf steps below
# write into $HOME and need to run as you, not root. This just makes sure
# you *can* sudo, and caches the credential so the apt-get/apt calls further
# down don't stop to prompt for a password in the middle of the script.
require_sudo

################################################################################
# Base packages
################################################################################
update_os_packages
clean_os_packages


################################################################################
# Debloat
################################################################################
# Telemetry/nag removal + snap removed in favor of flatpak (Flatpak
# section below installs it and the browsers). See lib/debloat.sh for
# what each of these actually does and why.
disable_telemetry
remove_snap


################################################################################
# Install Tools
################################################################################
sudo apt-get --yes install \
  curl \
  fzf \
  git \
  highlight \
  ranger \
  pandoc \
  shellcheck \
  shfmt \
  silversearcher-ag \
  tmux \
  tree \
  wget \
  xclip \


################################################################################
# Install Apps
################################################################################
sudo apt-get --yes install \
  evince \
  flameshot \
  gimp \
  keepassxc \
  libreoffice \
  peek \
  sakura \
  speedcrunch \
  stacer \
  virtualbox \
  vlc

install_flatpak

sudo flatpak install --system --noninteractive flathub org.mozilla.firefox
sudo flatpak install --system --noninteractive flathub org.chromium.Chromium
sudo flatpak install --system --noninteractive flathub com.github.PintaProject.Pinta


################################################################################
# Unattended updates (cron)
################################################################################
# Lets ubuntu_maintenance.sh run unattended on a schedule to keep OS packages
# and asdf-managed languages current - never a distro version upgrade (see
# upgrade_os_distro below for that), see update_os_packages (lib/util.sh).
# One-time setup; edit /etc/cron.d/dev_box_update directly to change the
# schedule later.
# install_unattended_apt_sudo
# install_update_cron_job


################################################################################
# OS distro upgrade (manual)
################################################################################
# Upgrades to the next available Ubuntu release, interim included (see
# configure_release_upgrade_prompt, lib/util.sh). Deliberately not run
# automatically and not part of ubuntu_maintenance.sh's cron job - a
# release upgrade needs you present, not running unattended while you
# might be using the box. Uncomment and run yourself when you're ready.
# upgrade_os_distro


################################################################################
# Dotfiles
################################################################################
# MANUAL prerequisite: clone this repo before running the rest of the script
#   mkdir -p ~/code && cd ~/code
#   git clone https://github.com/bdavi/dotfiles.git
#   cd dotfiles

"$DOTFILES_DIR/scripts/install_dotfiles.sh"


################################################################################
# XFCE
################################################################################
# Preferences that install_dotfiles.sh's symlinking can't keep in sync -
# see lib/configure_xfce.sh for why.
configure_xfce_theme
configure_xfce_terminal
configure_xfce_power_manager
configure_xfce_panel
configure_xfce_keyboard_shortcuts


################################################################################
# Vim
################################################################################
sudo apt-get --yes install vim-gtk3 # use this instead of just vim for clipboard integration

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +'PlugInstall --sync' +qa

################################################################################
# asdf
################################################################################
# install_asdf (lib/asdf_util.sh) is idempotent - installing here is the
# same operation ubuntu_maintenance.sh uses to keep it current.
install_asdf


################################################################################
# Languages (via asdf)
################################################################################
# Each asdf_install_* function (lib/asdf_langs.sh) is idempotent, same as
# install_asdf - used here and by ubuntu_maintenance.sh to keep languages
# current. asdf_cleanup_* prunes old versions down to the 2 most recent.
asdf_install_latest_ruby
asdf_cleanup_ruby

asdf_install_latest_nodejs
asdf_cleanup_nodejs

asdf_install_latest_elixir
asdf_cleanup_elixir

asdf_install_latest_python
asdf_cleanup_python


################################################################################
# Claude
################################################################################
# MANUAL: Claude Desktop has to be downloaded by hand (login-gated, no
# stable direct-download URL to script)
#   Download the .deb from https://claude.ai/download
#   sudo apt install ~/Downloads/claude-desktop_amd64.deb

# Claude Code CLI
# curl -fsSL https://claude.ai/install.sh | bash
# Installs to ~/.local/bin - already on PATH via config_files/.bashrc


################################################################################
# Maintenance
################################################################################
# Final pass - everything in ubuntu_maintenance.sh is idempotent, so safe
# to re-run here even though most of it (OS updates, asdf languages) was
# already covered above.
"$DOTFILES_DIR/scripts/dev_box/ubuntu_maintenance.sh"
