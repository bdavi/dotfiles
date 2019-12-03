#######################################################################
# The easy stuff
#######################################################################
sudo apt-get --yes install curl
sudo apt-get --yes install wget
sudo apt-get --yes install git
sudo apt-get --yes install npm
sudo apt-get --yes install tmux
sudo apt-get --yes install terminator
sudo apt-get --yes install arc-theme
sudo apt-get --yes install gimp
sudo apt-get --yes install flameshot
sudo apt-get --yes install chromium-browser
sudo apt-get --yes install synaptic
sudo apt-get --yes install exuberant-ctags
sudo apt-get --yes install fonts-powerline
sudo apt-get --yes install zeal


#######################################################################
# Oh my zsh
#######################################################################
sudo apt-get --yes install zsh

# Set default shell to zsh
sudo usermod -s /usr/bin/zsh $(whoami)

# External plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zdharma/fast-syntax-highlighting.git ~ZSH_CUSTOM/plugins/fast-syntax-highlighting
git clone https://github.com/djui/alias-tips.git ~ZSH_CUSTOM/plugins/alias-tips


#######################################################################
# Vim
#######################################################################
sudo apt-get --yes install vim
sudo apt-get --yes install vim-gtk #so that the system clipboard is available

# Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
cd ~/.fzf/
./install

# you complete me
sudo apt-get --yes install build-essential cmake python3-dev
cd ~/.vim/bundle/YouCompleteMe
python3 install.py --all


#######################################################################
# Yarn (Need later version of yarn for Rails)
#######################################################################
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install yarn


#######################################################################
# asdf-vm
#######################################################################
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.5

# Needed for most plugins
sudo apt-get --yes install \
  automake autoconf libreadline-dev \
  libncurses-dev libssl-dev libyaml-dev \
  libxslt-dev libffi-dev libtool unixodbc-dev \
  unzip curl

asdf update

# Set up for Ruby
sudo apt-get --yes install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev

asdf plugin-add python
asdf install ruby 2.6.5
asdf global ruby 2.6.5

# Set up for Python
sudo apt-get update
sudo apt-get --yes install --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

asdf plugin-add python
asdf install python 3.8.0
asdf install python 2.7.17
asdf global python 3.8.0

# Set up for Node
asdf plugin-add nodejs
sudo apt-get --yes install dirmngr
sudo apt-get --yes install gpg
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

asdf install nodejs 13.2.0
asdf global nodejs 13.2.0

#######################################################################
# Postgres
#######################################################################
sudo apt-get --yes install postgresql postgresql-contrib libpq-dev
systemctl start postgresql
systemctl enable postgresql


#######################################################################
# Install Albert
#######################################################################
curl https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -

sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_18.04/ /' > /etc/apt/sources.list.d/home:manuelschneid3r.list"
wget -nv https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_18.04/Release.key -O Release.key
sudo apt-key add - < Release.key
sudo apt-get update
sudo apt-get --yes install albert


#######################################################################
# Dotfiles
#######################################################################
git clone git@github.com:bdavi/dotfiles.git ~/code/dotfiles
~/code/dotfiles/scripts/dotfiles/dotfiles install


#######################################################################
# Handle by hand
#######################################################################
# Setup Zeal docsets

# Install Stacer: https://github.com/oguzhaninan/Stacer

# Install Slack

# Albert:
# hotkey: meta + space
# Set the application to:
# Ignore OnlyShowin/NotShowin keys
# Additionally use generic name for lookup
# Fuzzy

# XFCE
# Clock custom format for top bar: %a %d %b, %l:%M%P
# In apperance select arc-dark. Set font size to 12.

# Keep trackpad from doing stuff while typing.
# Add to startup
# https://askubuntu.com/questions/299868/disable-touchpad-while-typing-does-not-work
# syndaemon -i 1 -K -d
