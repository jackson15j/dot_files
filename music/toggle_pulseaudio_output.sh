#!/bin/bash
#
# Quick script that toggles between my laptop audio and my Office speakers that
# are connected to a RaspberryPi running Volumio. NOTE: I have previously set
# up Volumio to expose itself as a ROAP client, as well as allowing the laptop
# to use ROAP speakers as an audio sink.


# Steps:
#
# * Identify my Laptops speakers as an output sink:
#
# ```bash
# $ pactl list short sinks | grep analog-stereo | awk '{print $ 1}'
# 0
# ```
#
# * Identify my Volumio connected speakers as an output sink, but limit to
#   first match!! (I sometimes have ethernet and wifi connected at the same
#   time.
#
# ```bash
# $ pactl list short sinks | grep -m 1 volumio-office | awk '{print $ 1}'
# 25
# ```
#
# * Finally, toggle between the outputs based on the RUNNING/SUSPENDED state.
#
# ```bash
# $ pactl list short sinks | grep RUNNING | awk '{print $ 1}'
# 0
# ```
# $ pacmd set-default-sink 25
# ```

LAPTOP_SPEAKERS=$(pactl list short sinks | grep analog-stereo | awk '{print $ 1}')
VOLUMIO_SPEAKERS=$(pactl list short sinks | grep -m1 volumio-office | awk '{print $ 1}')
CURRENT_SPEAKERS=$(pactl list short sinks | grep RUNNING | awk '{print $ 1}')


case "$CURRENT_SPEAKERS" in
    $LAPTOP_SPEAKERS)
        echo "Toggling output to Volumio Speakers..."
        pacmd set-default-sink $VOLUMIO_SPEAKERS
        ;;
    $VOLUMIO_SPEAKERS)
        echo "Toggling output to Laptop Speakers..."
        pacmd set-default-sink $INPUT $LAPTOP_SPEAKERS
        ;;
    *)
        echo "-- Debug: Pulse input/output sources before:"
        echo -e "$(pacmd list-sources)"
        echo "-- CURRENT_SPEAKERS: $CURRENT_SPEAKERS"
        echo "-- LAPTOP_SPEAKERS: $LAPTOP_SPEAKERS"
        echo "-- VOLUMIO_SPEAKERS: $VOLUMIO_SPEAKERS"

        echo "Unexpected output sink. Setting to Laptop Speakers..."
        pacmd set-default-sink $INPUT $LAPTOP_SPEAKERS

        echo
        echo "-- Debug: Pulse input/output sources after:"
        echo -e "$(pacmd list-sources)"
        exit 0
esac
