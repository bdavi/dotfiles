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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/util.sh"

#############################################################################
# Sudo
#############################################################################
# Run as your normal user (not root) - the dotfiles/vim/fzf steps below
# write into $HOME and need to run as you, not root. This just makes sure
# you *can* sudo, and caches the credential so the apt-get/apt calls further
# down don't stop to prompt for a password in the middle of the script.
require_sudo

#############################################################################
# Base packages
#############################################################################
sudo apt-get update

sudo apt-get --yes install curl git ranger highlight silversearcher-ag \
  tmux tree wget xclip shellcheck keepassxc firefox sakura shfmt


#############################################################################
# Dotfiles
#############################################################################
# MANUAL prerequisite: clone this repo before running the rest of the script
#   mkdir -p ~/code && cd ~/code
#   git clone https://github.com/bdavi/dotfiles.git
#   cd dotfiles

"$DOTFILES_DIR/scripts/install_dotfiles.sh"


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
# asdf
#############################################################################
# Installing is the same operation as updating for a pinned-version binary,
# so this just delegates to the update script - see it for how the version
# is resolved and kept pinned to a major version.
"$DOTFILES_DIR/scripts/dev_box/update_ubuntu.sh"


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
