sudo apt-get update

###############################################################################
# Basics
###############################################################################
# So we can compile stuff
sudo apt-get --yes install build-essential libssl-dev zlib1g-dev libreadline-dev libyaml-dev libxml2-dev libxslt1-dev libffi-dev libcurl4-openssl-dev python-software-properties

# A few tools
sudo apt-get --yes install git curl vim tmux wget

###############################################################################
# Languages/Frameworks
###############################################################################
# Node/JS - Using NVM
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
nvm install 6.11.2
nvm use 6.11.2

sudo ln -s /usr/bin/nodejs /usr/bin/node

sudo apt-get --yes install npm
sudo npm install i -g bower ember-cli mocha yarn

# Python - Using vitrualenv
sudo apt-get --yes install python python-dev python3 python3-dev python-pip
sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv

# Ruby/Rails - Using rbenv
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install 2.3.1
rbenv install 2.4.1
rbenv global 2.4.1

gem install bundler foreman rails:5.1.3

rbenv rehash

###############################################################################
# Databases
###############################################################################
# PostgreSQL
sudo apt-get install --yes postgresql postgresql-contrib pgadmin3
sudo update-rc.d postgresql enable
sudo service postgresql start

# Redis
sudo apt-get install --yes redis-server

###############################################################################
# Applications
###############################################################################
# The easy ones
sudo apt-get --yes install vlc browser-plugin-vlc synaptic gimp shutter filezilla kdenlive chromium-browser virtualbox virtualbox-ext-pack imagemagick
