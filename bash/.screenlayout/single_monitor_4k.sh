#!/bin/sh
# https://mrwaggel.be/post/xrandr-virtual-splitscreen-cookbook/

# Delete pre-existing virtual monitors.
for x in $(xrandr --listmonitors); do xrandr --delmonitor $x;done
# Setting a single DP1 attached 4K screen.
xrandr --output DP1 --primary --mode 3840x2160 --pos 0x0 --rotate normal --output DP2 --off --output DP3 --off --output HDMI1 --off --output HDMI2 --off --output HDMI3 --off --output VIRTUAL1 --off
# Toggle the frame buffer to make it refresh to the new display.
xrandr --fb 3840x2161; xrandr --fb 3840x2160
