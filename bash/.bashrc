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
