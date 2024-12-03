###############################################################################
# OH-MY-ZSH
###############################################################################
export DISABLE_MAGIC_FUNCTIONS=true
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="avit"
HYPHEN_INSENSITIVE="true"

plugins=(
  asdf
  colored-man-pages
  command-not-found
  gem
  git
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

  # append completions to fpath
  fpath=(${ASDF_DIR}/completions $fpath)
  # initialise completions with ZSH's compinit
  autoload -Uz compinit && compinit
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
