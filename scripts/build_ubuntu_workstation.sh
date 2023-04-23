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
# Databases
#######################################################################

# postgres
sudo apt-get --yes install postgresql postgresql-contrib libpq-dev

sudo systemctl start postgresql

sudo systemctl enable postgresql

sudo -i -u postgres psql postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';"

sudo -i -u postgres psql postgres -c "CREATE USER brian WITH SUPERUSER;"
sudo -i -u postgres psql postgres -c "ALTER USER brian WITH SUPERUSER;"

# Redis
sudo apt-get --yes install redis-server
sudo systemctl start redis-server.service
sudo systemctl enable redis-server.service

# tableplus
wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/tableplus-archive.gpg > /dev/null

sudo add-apt-repository "deb [arch=amd64] https://deb.tableplus.com/debian/22 tableplus main"

sudo apt update
sudo apt install tableplus

# DBeaver
flatpak install flathub io.dbeaver.DBeaverCommunity

#######################################################################
# Docker
#######################################################################

sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update

sudo apt-get install ca-certificates curl gnupg lsb-release

sudo mkdir -m 0755 -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo apt-install docker-compose

sudo groupadd docker

sudo usermod -aG docker ${USER}

su -s ${USER}



#######################################################################
# Touchegg - touchpad gestures
#######################################################################
sudo add-apt-repository ppa:touchegg/stable
sudo apt update
sudo apt install touchegg




#######################################################################
# Misc
#######################################################################
# Need this to make guard work with spring on larger projects.
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p



