#!/bin/bash
EXTERNAL="HDMI2"
PRIMARY="eDP1"

function get_displays()
{
    xrandr -q | grep connected | awk '{print $1}'
}

function get_disconnected_displays()
{
    xrandr -1 | grep disconnected | awk '{print $1}'
}

function get_resolution()
{
    [[ -z "$1" ]] && return 0 || xrandr -q | grep -A1 $1 | tail -1 | awk '{print $1}' | grep -e "^[0-9]"
}

for display in $(get_displays); do
    resolution=`get_resolution $display`
    echo $display $resolution

    [[ $display == $PRIMARY ]] && arg="--primary";
    [[ -n $resolution ]] && mode="--mode $resolution";

    if [[ $display == $EXTERNAL ]]; then
        echo setting $display to $arg $mode
        xrandr --output $display $arg $mode
    elif [[ -n $mode ]]; then
        echo turning $display off
        xrandr --output $display --off
    fi
    unset mode arg resolution;
done
