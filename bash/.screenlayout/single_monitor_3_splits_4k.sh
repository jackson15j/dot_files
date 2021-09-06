#!/bin/sh
# xrandr --output DP1 --primary --mode 3840x2160 --pos 0x0 --rotate normal --output DP2 --off --output DP3 --off --output HDMI1 --off --output HDMI2 --off --output HDMI3 --off --output VIRTUAL1 --off
# DP1 connected primary 3840x2160+0+0 (normal left inverted right x axis y axis) 610mm x 350mm

# https://mrwaggel.be/post/xrandr-virtual-splitscreen-cookbook/

# Delete pre-existing virtual monitors.
for x in $(xrandr --listmonitors); do xrandr --delmonitor $x;done
# Setting a 3 screen (2x1) virtual monitor.
xrandr --setmonitor VIRT-LEFT-TOP 1920/305x1080/175+0+0 DP-1
xrandr --setmonitor VIRT-LEFT-BOT 1920/305x1080/175+0+1080 none
xrandr --setmonitor VIRT-RIGHT 1920/305x2160/350+1920+0 none
# Toggle the frame buffer to make it refresh to the new display.
xrandr --fb 3840x2161; xrandr --fb 3840x2160
