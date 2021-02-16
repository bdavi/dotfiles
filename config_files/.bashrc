################################################################################
# Git Prompt
################################################################################
# Based on:
# - https://github.com/jcgoble3/gitstuff/blob/master/gitprompt.sh
# - https://gist.github.com/henrik/31631
# - https://gist.github.com/srguiwiz/de87bf6355717f0eede5

git_branch() {
    git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

git_status() {
    local status="$(git status --porcelain 2>/dev/null)"
    local output=''
    [[ -n $(egrep '^[MADRC]' <<<"$status") ]] && output="$output+"
    [[ -n $(egrep '^.[MD]' <<<"$status") ]] && output="$output!"
    [[ -n $(egrep '^\?\?' <<<"$status") ]] && output="$output?"
    [[ -n $(git stash list) ]] && output="${output}S"
    [[ -n $(git log --branches --not --remotes) ]] && output="${output}P"
    [[ -n $output ]] && output="|$output"  # separate from branch name
    echo $output
}

git_color() {
    local staged=$([[ $1 =~ \+ ]] && echo yes)
    local dirty=$([[ $1 =~ [!\?] ]] && echo yes)
    if [[ -n $staged ]] && [[ -n $dirty ]]; then
        echo -e '\033[1;33m'  # bold yellow
    elif [[ -n $staged ]]; then
        echo -e '\033[1;32m'  # bold green
    elif [[ -n $dirty ]]; then
        echo -e '\033[1;31m'  # bold red
    else
        echo -e '\033[1;37m'  # bold white
    fi
}

git_prompt() {
    local branch=$(git_branch)
    if [[ -n $branch ]]; then
        local state=$(git_status)
        local color=$(git_color $state)
        # Now output the actual code to insert the branch and status
        echo -e "\x01$color\x02[$branch$state]\x01\033[00m\x02"  # last bit resets color
    fi
}


################################################################################
# Set up my preferred prompt
################################################################################
export PS1="\e[0;32m\u@\h\e[m \e[0;36m \w\e[m  \$(git_prompt)\n$"


###############################################################################
# asdf (version manager)
###############################################################################
if [ -d "$HOME/.asdf" ] 
then
  . $HOME/.asdf/asdf.sh
  . $HOME/.asdf/completions/asdf.bash
fi


################################################################################
# Additional configuration
################################################################################
source ~/.git-completion.bash
source ~/.commonrc


################################################################################
# Aliases
################################################################################
alias source!='source ~/.bashrc; tmux source-file ~/.tmux.conf; tmux display-message "SOURCED!"'
source /usr/share/google-cloud-sdk/completion.bash.inc
source ~/monorepo/zlaverse/support/bash_functions.sh


################################################################################
# Work
################################################################################
if [ -d "$HOME/monorepo" ]
then
  source /usr/share/google-cloud-sdk/completion.bash.inc
  source ~/monorepo/zlaverse/support/bash_functions.sh
  export COMPOSE_FILE=./docker-compose.yml:./docker-compose-linux.yml
fi
