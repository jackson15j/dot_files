#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias pacman='pacman --color auto'

source ~/.bash_prompt

# https://wiki.archlinux.org/index.php/Ruby#Setup
export PATH=$PATH:$(ruby -e 'print Gem.user_dir')/bin

# >>> Added by cnchi installer
BROWSER=/usr/bin/chromium
EDITOR=/usr/bin/nano

# added by travis gem
[ -f $HOME/.travis/travis.sh ] && source $HOME/.travis/travis.sh

# Python's `pipenv` stores `.venv` in project folder instead of `/tmp`:
# https://pipenv.readthedocs.io/en/latest/advanced/#pipenv.environments.PIPENV_VENV_IN_PROJECT
export PIPENV_VENV_IN_PROJECT=true
