#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias pacman='pacman --color auto'

## virtualenv
[ -d $HOME/virtual_envs ] && export WORKON_HOME=$HOME/virt_envs
[ -f /usr/bin/virtualenvwrapper.sh ] && source /usr/bin/virtualenvwrapper.sh

source ~/.bash_prompt

# https://wiki.archlinux.org/index.php/Ruby#Setup
export PATH=$PATH:$(ruby -e 'print Gem.user_dir')/bin

# >>> Added by cnchi installer
BROWSER=/usr/bin/chromium
EDITOR=/usr/bin/nano

# added by travis gem
[ -f $HOME/.travis/travis.sh ] && source $HOME/.travis/travis.sh
