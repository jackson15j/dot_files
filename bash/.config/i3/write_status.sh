#!/bin/bash
#
mkdir -p /tmp/i3/status
touch /tmp/i3/status/dunst
touch /tmp/i3/status/todo_org
touch /tmp/i3/status/spotifyd
# Pull in display into environment. Needs to be done after the desktop has
# loaded.
# Dunst needs this, else if fails with no display until the first notification
# is sent (which restarts the failed service).
# https://github.com/dunst-project/dunst/issues/347
# systemctl --user import-environment DISPLAY

dunst_status () {
    # Get the status for the dunst notification service.
    if [ $(dunstctl is-paused) = "false" ];
    then
        echo "Enabled" > /tmp/i3/status/dunst
    else
        echo "DoNotDisturb" > /tmp/i3/status/dunst
    fi
}

todo_org_status () {
    # Get the TODO counts for my org files.
    echo "TODO: $(grep TODO ~/org/todo.org | wc -l)" > /tmp/i3/status/todo_org
}

while true;
do
    echo "start of while loop"
    dunst_status
    todo_org_status
    echo "about to sleep..."
    sleep 5
done
