################################################################################
# A few basics
################################################################################

# Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Allows us to remap caplock to escape because I'm not an animal.
brew cask install karabiner-elements

# The important stuff
brew install tmux
brew install macvim --with-override-system-vim
brew install reattach-to-user-namespace # Fix copy mode in vim/tmux

################################################################################
# Some apps
################################################################################
brew cask install alfred
brew install wget
brew cask install google-chrome
brew cask install skitch
brew cask install iterm2
brew cask install spectacle
brew cask install twist
brew cask install slack
brew cask install gimp
brew cask install spotify
brew cask install virtualbox

# Install Vundle so we can install plugins in vim
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# Need The Silver Searcher for faster nerdtree lookups in vim
brew install the_silver_searcher


################################################################################
# GitHub SSH Setup
################################################################################
ssh-keygen -t rsa -C "brian@briandavies.me"

# Paste this output at github ( https://github.com/settings/ssh )
# cat ~/.ssh/id_rsa.pub
# Verify with:
# ssh -T git@github.com


################################################################################
# Ruby/Rails
################################################################################
brew install rbenv ruby-build
rbenv install 2.3.3
rbenv install 2.4.1
rbenv install 2.5.3
rbenv global 2.5.3
gem install bundler foreman rails:5.1.3 sqlite3


################################################################################
# Postgres
################################################################################
brew install postgresql
brew services start postgresql


################################################################################
# Node
################################################################################
# Install NVM
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

nvm install node
nvm install 6.11.2
nvm use 6.11.2
brew install npm
npm install i -g bower ember-cli mocha yarn


################################################################################
# Redis
################################################################################
brew install redis
brew services start redis


################################################################################
# Heroku
################################################################################
brew install heroku/brew/heroku


################################################################################
# Fix weird Mojavie stuff
################################################################################
sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /


################################################################################
# Python
################################################################################
brew install pyenv
sudo easy_install pip


