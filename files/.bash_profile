# Set up my preferred prompt
export PS1="\e[0;32m\u@\h\e[m \e[0;36m \w\e[m\n$"

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

# Add Postgres bin to path
PATH=$PATH:/Library/PostgreSQL/9.5/bin/
