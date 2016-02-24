
# Include git status/branch in prompt
# https://gist.github.com/srguiwiz/de87bf6355717f0eede5
function git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

# http://unix.stackexchange.com/questions/88307/escape-sequences-with-echo-e-in-different-shells
function markup_git_branch {
  if [[ "x$1" = "x" ]]; then
    echo -e "[$1]"
  else
    if [[ $(git status 2> /dev/null | tail -n1) = "nothing to commit, working directory clean" ]]; then
      echo -e '\033[1;32m['"$1"']\033[0;30m'
    else
      echo -e '\033[1;31m['"$1"'*]\033[0;30m'
    fi
  fi
}

# Set up my preferred prompt
export PS1="\e[0;32m\u@\h\e[m \e[0;36m \w\e[m  $(markup_git_branch $(git_branch)) \e[m \n$"

# Command aliases
alias ll='clear;ls -lah'
alias vim='mvim -v'
alias c='clear'

# PostgreSQL
alias pg.start='sudo -u postgres pg_ctl -D /Library/PostgreSQL/9.5/data start'
alias pg.stop='sudo -u postgres pg_ctl -D /Library/PostgreSQL/9.5/data stop'

# Make sure rbenv is running
eval "$(rbenv init -)"

# Add my custom scripts folder to the path
PATH=$PATH:~/code/scripts

# Set up PostgreSQL
PATH=$PATH:/Library/PostgreSQL/9.5/bin/
export PGHOST=localhost
