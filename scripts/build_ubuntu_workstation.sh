#!/usr/bin/env bash

sudo apt-get update


###########################################################################
# The basic tools
###########################################################################

sudo apt-get --yes install curl git ranger highlight silversearcher-ag \
  tmux tree wget xclip pandoc


###########################################################################
# A few apps
###########################################################################
sudo apt-get --yes install chromium-browser evince flameshot gimp peek \
  keepassxc libreoffice pinta speedcrunch sakura virtualbox stacer vlc


#######################################################################
# Dotfiles
#######################################################################
cp -rsf ~/code/dotfiles/config_files/. ~


#######################################################################
# zsh
#######################################################################
sudo apt-get --yes install zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set default shell to zsh
sudo usermod -s /usr/bin/zsh $(whoami)


###########################################################################
# ASDF
###########################################################################
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.2

asdf update


# Dependencies needed for many plugins
sudo apt-get --yes install \
  automake autoconf libreadline-dev \
  libncurses-dev libssl-dev libyaml-dev \
  libxslt-dev libffi-dev libtool unixodbc-dev \
  unzip curl


# Nodejs
sudo apt-get install python3 g++ make python3-pip
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs latest
asdf global nodejs $(asdf latest nodejs)


# Ruby
sudo apt-get --yes install autoconf bison build-essential \
  libssl-dev libyaml-dev libreadline6-dev zlib1g-dev \
  libncurses5-dev libffi-dev libgdbm-dev

asdf plugin-add ruby
asdf install ruby latest
asdf global ruby $(asdf latest ruby)

gem install bundler
gem install guard
gem install rails
gem install rubocop


# Python
sudo apt-get --yes install --no-install-recommends make build-essential \
  libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
  wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev

asdf plugin-add python

asdf install python 2.7.17
asdf install python latest
asdf global python $(asdf latest python) 2.7.17


# Yarn
asdf plugin-add yarn
asdf install yarn latest
asdf global yarn $(asdf latest yarn)


# Erlang
sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang latest
asdf global erlang $(asdf latest erlang)


# Elixir
# Make sure Erlang is installed
sudo apt-get install unzip

asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install elixir latest
asdf global elixir $(asdf latest elixir)


#######################################################################
# Vim
#######################################################################
sudo apt-get --yes install vim-gtk3 # use this instead of just vim for clipboard integration

# # Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +'PlugInstall --sync' +qa


#######################################################################
# Misc
#######################################################################
# Need this to make guard work with spring on larger projects.
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
