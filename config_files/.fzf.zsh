# Setup fzf
# ---------
if [[ ! "$PATH" == */home/brian/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/home/brian/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/brian/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/brian/.fzf/shell/key-bindings.zsh"
