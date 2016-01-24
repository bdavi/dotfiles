# Set up my preferred prompt
export PS1="\e[0;32m\u@\h\e[m \e[0;36m \w\e[m\n$"

# Command aliases
alias ll='clear;ls -lah'
alias vim='mvim -v'
alias c='clear'

# Make sure rbenv is running
eval "$(rbenv init -)"

# Add my custom scripts folder to the path
PATH=$PATH:~/code/scripts


