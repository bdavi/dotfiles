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

################################################################################
# Command aliases
################################################################################
alias ll='clear;ls -lah'
alias c='clear'
alias be='bundle exec'
alias ber='bundle exec rspec'
alias gl="git log --pretty=format:'%C(yellow)%h%C(reset) - %an [%C(green)%ar%C(reset)] %s' --graph"
alias annotate-model='annotate --exclude tests,fixtures,factories,serializers'
alias nt='nosetests'
alias rmpyc='find . -name "*.pyc" -type f -delete'
alias das='dev_appserver.py ./'
alias source!='source ~/.bash_profile'
alias pv='python -m virtualenv venv && source venv/bin/activate && pip install -r requirements.txt'
alias rename='tmux rename-window'
alias mig='bundle exec rake db:migrate && bundle exec rake db:migrate RAILS_ENV=test'
alias eb='ember build'

# Typos
alias cim='vim'


################################################################################
# Editor
################################################################################
export EDITOR='vim'

################################################################################
# Git Completion
################################################################################
source ~/.git-completion.bash

################################################################################
# rbenv
################################################################################
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

################################################################################
# NVM
################################################################################
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

################################################################################
# Shell
################################################################################
export PATH=$PATH:~/code/dotfiles/scripts
