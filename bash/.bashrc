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
EDITOR="emacsclient -t"

# added by travis gem
[ -f $HOME/.travis/travis.sh ] && source $HOME/.travis/travis.sh

# Python's `pipenv` stores `.venv` in project folder instead of `/tmp`:
# https://pipenv.readthedocs.io/en/latest/advanced/#pipenv.environments.PIPENV_VENV_IN_PROJECT
export PIPENV_VENV_IN_PROJECT=true

# Can't sign via gpg??
# tutorials.technology/solved_errors/21-gpg-signing-failed-Inappropriate-ioctl-for-device.html
export GPG_TTY=$(tty)

# Manjaro: Default keymap for `[Shift+]AltGr+#` does not give backslash (`\`)
# or bar/pipe (`|`). Added a new `xkbmap` that can is loaded to correct this.
export DISPLAY=:0.0
xkbcomp -w 0 /home/craig/github_repos/dot_files/keyboards/vortex_core/xkbmap $DISPLAY

# Unlock the gnome-keyring on start of the windows manager.
# https://wiki.archlinux.org/index.php/GNOME/Keyring#With_a_display_manager
if [ -n "$DESKTOP_SESSION" ];then
    eval $(gnome-keyring-daemon --start)
    export SSH_AUTH_SOCK
fi

# Put global NPM packages in a RW location.
# https://wiki.archlinux.org/title/node.js_#Allow_user-wide_installations
export npm_config_prefix="$HOME/.local"
