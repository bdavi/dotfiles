# Thank you internet
# https://github.com/jcgoble3/gitstuff/blob/master/gitprompt.sh
# Adds the current branch to the bash prompt when the working directory is
# part of a Git repository. Includes color-coding and indicators to quickly
# indicate the status of working directory.
#
# To use: Copy into ~/.bashrc and tweak if desired.
#
# Based upon the following gists:
# <https://gist.github.com/henrik/31631>
# <https://gist.github.com/srguiwiz/de87bf6355717f0eede5>
# Modified by me, using ideas from comments on those gists.
#
# License: MIT, unless the authors of those two gists object :)

git_branch() {
    # -- Finds and outputs the current branch name by parsing the list of
    #    all branches
    # -- Current branch is identified by an asterisk at the beginning
    # -- If not in a Git repository, error message goes to /dev/null and
    #    no output is produced
    git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

git_status() {
    # Outputs a series of indicators based on the status of the
    # working directory:
    # + changes are staged and ready to commit
    # ! unstaged changes are present
    # ? untracked files are present
    # S changes have been stashed
    # P local commits need to be pushed to the remote
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
    # Receives output of git_status as argument; produces appropriate color
    # code based on status of working directory:
    # - White if everything is clean
    # - Green if all changes are staged
    # - Red if there are uncommitted changes with nothing staged
    # - Yellow if there are both staged and unstaged changes
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
    # First, get the branch name...
    local branch=$(git_branch)
    # Empty output? Then we're not in a Git repository, so bypass the rest
    # of the function, producing no output
    if [[ -n $branch ]]; then
        local state=$(git_status)
        local color=$(git_color $state)
        # Now output the actual code to insert the branch and status
        echo -e "\x01$color\x02[$branch$state]\x01\033[00m\x02"  # last bit resets color
    fi
}

# Set up my preferred prompt
export PS1="\e[0;32m\u@\h\e[m \e[0;36m \w\e[m  \$(git_prompt)\n$"

# Command aliases
alias ll='clear;ls -lah'
alias vim='mvim -v'
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

# Make sure rbenv is running
eval "$(rbenv init -)"

# Add my custom scripts folder to the path
PATH=$PATH:~/code/dotfiles/scripts
PATH=$PATH:~/code/utilities

# Make sure ssh keys are in keychain
ssh-add -A 2>/dev/null;

# Set up PostgreSQL
PATH=$PATH:/Library/PostgreSQL/9.5/bin
export PGHOST=localhost
alias pg.start='sudo -u postgres pg_ctl -D /Library/PostgreSQL/9.5/data start'
alias pg.stop='sudo -u postgres pg_ctl -D /Library/PostgreSQL/9.5/data stop'

# Editor
export EDITOR='mvim -v'

#auto complete
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/brian/code/google-cloud-sdk/path.bash.inc' ]; then source '/Users/brian/code/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/brian/code/google-cloud-sdk/completion.bash.inc' ]; then source '/Users/brian/code/google-cloud-sdk/completion.bash.inc'; fi
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
