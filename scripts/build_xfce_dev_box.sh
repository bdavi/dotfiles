#!/usr/bin/env bash

#############################################################################
# Xubuntu dev box bootstrap
#############################################################################
# Assumes a fresh install of Xubuntu using the "minimal install" option.
#
# Not everything here can be run unattended - a few steps require a GUI or
# a manual download and are left as comments describing exactly what to do.
# Run the rest top-to-bottom.
#############################################################################

set -euo pipefail

#############################################################################
# Sudo
#############################################################################
# Run as your normal user (not root) - the dotfiles/vim/fzf steps below
# write into $HOME and need to run as you, not root. This just makes sure
# you *can* sudo, and caches the credential so the apt-get/apt calls further
# down don't stop to prompt for a password in the middle of the script.
if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root/sudo." >&2
  exit 1
fi

if ! sudo -v; then
  echo "This script requires sudo privileges." >&2
  exit 1
fi

# Keep the sudo timestamp alive for the lifetime of this script.
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" 2>/dev/null || exit
done 2>/dev/null &

#############################################################################
# Base packages
#############################################################################
sudo apt-get update

sudo apt-get --yes install curl git ranger highlight silversearcher-ag \
  tmux tree wget xclip shellcheck keepassxc firefox sakura


#############################################################################
# Dotfiles
#############################################################################
# MANUAL prerequisite: clone this repo before running the rest of the script
#   mkdir -p ~/code && cd ~/code
#   git clone https://github.com/bdavi/dotfiles.git
#   cd dotfiles

~/code/dotfiles/scripts/install_dotfiles.sh


#############################################################################
# Vim
#############################################################################
sudo apt-get --yes install vim-gtk3 # use this instead of just vim for clipboard integration

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +'PlugInstall --sync' +qa


#############################################################################
# fzf
#############################################################################
# --no-update-rc: don't touch .bashrc/.zshrc, config_files/.bashrc and
# config_files/.zshrc already source ~/.fzf.bash / ~/.fzf.zsh
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc


#############################################################################
# Claude
#############################################################################
# MANUAL: Claude Desktop has to be downloaded by hand (login-gated, no
# stable direct-download URL to script)
#   Download the .deb from https://claude.ai/download
#   sudo apt install ~/Downloads/claude-desktop_amd64.deb

# Claude Code CLI
curl -fsSL https://claude.ai/install.sh | bash
# Installs to ~/.local/bin - already on PATH via config_files/.bashrc
