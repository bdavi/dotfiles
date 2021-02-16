###############################################################################
# OH-MY-ZSH
###############################################################################
export DISABLE_MAGIC_FUNCTIONS=true
export ZSH="$HOME/.oh-my-zsh"
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
source ~/.commonrc


################################################################################
# Aliases
################################################################################
alias source!='source ~/.zshrc; tmux source-file ~/.tmux.conf; tmux display-message "SOURCED!"'


###############################################################################
# asdf (version manager)
###############################################################################
if [ -d "$HOME/.asdf" ] 
then
  . $HOME/.asdf/asdf.sh
fi

################################################################################
# Work
################################################################################
source /usr/share/google-cloud-sdk/completion.bash.inc
source ~/monorepo/zlaverse/support/bash_functions.sh
export COMPOSE_FILE=./docker-compose.yml:./docker-compose-linux.yml
