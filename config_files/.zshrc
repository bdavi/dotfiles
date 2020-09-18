###############################################################################
# OH-MY-ZSH
###############################################################################
export DISABLE_MAGIC_FUNCTIONS=true
export ZSH="/home/brian/.oh-my-zsh"
export ZSH_THEME="avit"
HYPHEN_INSENSITIVE="true"

plugins=(
  alias-tips
  asdf
  colored-man-pages
  command-not-found
  fast-syntax-highlighting
  gem
  git
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh
source ~/code/dotfiles/config_files/.commonrc


################################################################################
# Terminal
################################################################################
set -ga terminal-overrides ",xterm-256color:Tc"


################################################################################
# Aliases
################################################################################
alias source!='source ~/.zshrc; tmux source-file ~/.tmux.conf; tmux display-message "SOURCED!"'


###############################################################################
# asdf (version manager)
###############################################################################
. $HOME/.asdf/asdf.sh


###############################################################################
# fzf search
###############################################################################
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
