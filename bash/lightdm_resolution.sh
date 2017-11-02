#!/bin/bash
# https://askubuntu.com/questions/119843/how-to-force-multiple-monitors-correct-resolutions-for-lightdm#331991
# http://www.sudo-juice.com/lightdm-resolution/
# https://askubuntu.com/questions/73804/wrong-login-screen-resolution/331988#331988
LAPTOP="eDP1"

function get_resolution()
{
    [[ -z "$1" ]] && return 0 || xrandr -q | grep -A1 $1 | tail -1 | awk '{print $1}' | grep -e "^[0-9]"
}

function get_connected_displays()
{
    xrandr -q | grep connected | grep -v disconnected | awk '{print $1}'
}

function get_disconnected_displays()
{
    xrandr -q | grep disconnected | awk '{print $1}'
}

# Aim:
#  xrandr --output eDP1 --primary --mode 2560x1440 --output HDMI2 --mode 1920x1080 --above eDP1
#  xrandr --output eDP1 --primary --mode 2560x1440
options=""
for display in $(get_connected_displays); do
    resolution=`get_resolution $display`
    echo $display $resolution

    [[ $display == $LAPTOP ]] && arg="--primary";
    [[ -n $resolution ]] && mode="--mode $resolution";
    [[ $display != $LAPTOP ]] && location="--above $LAPTOP";

    options="${options} --output $display $arg $mode $location"
    echo setting $display to $arg $mode

    unset arg mode resolution
done

echo setting: xrander $options
xrandr $options
