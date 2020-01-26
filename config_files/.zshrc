###############################################################################
# OH-MY-ZSH
###############################################################################
export DISABLE_MAGIC_FUNCTIONS=true
export ZSH="/home/brian/.oh-my-zsh"
export ZSH_THEME="avit"
HYPHEN_INSENSITIVE="true"

plugins=(
  alias-tips
  colored-man-pages
  command-not-found
  fast-syntax-highlighting
  gem
  git
  npm
  pip
  python
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh


###############################################################################
# System
###############################################################################
/usr/bin/setxkbmap -option "caps:swapescape"
alias swapesc="/usr/bin/setxkbmap -option \"caps:swapescape\""


###############################################################################
# Editor
###############################################################################
export EDITOR='vim'
alias cim='vim' # Becuase I can't type!!


###############################################################################
# Shell / Tmux
###############################################################################
alias c="clear"
alias ll="ls -lah"
alias rename='tmux rename-window'
set -ga terminal-overrides ",xterm-256color:Tc"
alias source!='source ~/.zshrc; tmux source-file ~/.tmux.conf; tmux display-message "SOURCED!"'
alias vc='vim -p ~/.vimrc ~/.zshrc ~/.tmux.conf'


###############################################################################
# Git
###############################################################################
alias gl="git log --pretty=format:'%C(yellow)%h%C(reset) - %an [%C(green)%ar%C(reset)] %s' --graph"
alias gdc='git diff --cached'
alias gdm='git diff master..$(git rev-parse --abbrev-ref HEAD)'
alias ga.='git add .'


###############################################################################
# Ruby/Rails
###############################################################################
alias be='bundle exec'
alias ber='bundle exec rspec'
alias annotate-model='annotate --exclude tests,fixtures,factories,serializers'
alias am='annotate --exclude tests,fixtures,factories,serializers'
alias mig='bundle exec rake db:migrate && bundle exec rake db:migrate RAILS_ENV=test'
alias rb='bundle exec rake db:rollback && bundle exec rake db:rollback RAILS_ENV=test'


###############################################################################
# Yarn
###############################################################################
alias yt='yarn test'


###############################################################################
# Ember
###############################################################################
alias eb='ember build'


###############################################################################
# asdf (version manager)
###############################################################################
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash


###############################################################################
# Rust / Cargo
###############################################################################
source $HOME/.cargo/env
export RUST_SRC_PATH=/usr/local/src/rust/src


###############################################################################
# fzf search
###############################################################################
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


###############################################################################
# Path
###############################################################################
export PATH=$PATH:~/code/dotfiles/scripts
