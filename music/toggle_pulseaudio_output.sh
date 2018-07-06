#!/bin/bash
#
# Quick script that toggles between my laptop audio and my Office speakers that
# are connected to a RaspberryPi running Volumio. NOTE: I have previously set
# up Volumio to expose itself as a ROAP client, as well as allowing the laptop
# to use ROAP speakers as an audio sink.


# Steps:
#
# * Identify my input that I need to move between output sinks:
#
# ```bash
# $ pactl list short sink-inputs | awk '{print $0}'
# 367     0       147     protocol-native.c       s24-32le 2ch 192000Hz
# ```
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
# $ pactl move-sink-input 367 25
# ```

INPUT=$(pactl list short sink-inputs | awk '{print $1}')
LAPTOP_SPEAKERS=$(pactl list short sinks | grep analog-stereo | awk '{print $ 1}')
VOLUMIO_SPEAKERS=$(pactl list short sinks | grep -m1 volumio-office | awk '{print $ 1}')
CURRENT_SPEAKERS=$(pactl list short sinks | grep RUNNING | awk '{print $ 1}')


# INVESTIGATE: Why doesn't this if condition work, when the case statement
# does. NOTE: I've tried the whole range of `-eq` and `==` with and without the
# variables quoted.
#
# if [[ $CURRENT_RUNNING -eq $LAPTOP_SPEAKERS ]]
# then
#    echo "Toggling output to Volumio Speakers..."
#    pactl move-sink-input $INPUT $VOLUMIO_SPEAKERS
# elif [[ $CURRENT_RUNNING -eq $VOLUMIO_SPEAKERS ]]
# then
#     echo "Toggling output to Laptop Speakers..."
#     pactl move-sink-input $INPUT $LAPTOP_SPEAKERS
# else
#     echo "Unexpected output sink. Setting to Laptop Speakers..."
#     pactl move-sink-input $INPUT $LAPTOP_SPEAKERS
# fi


case "$CURRENT_SPEAKERS" in
    $LAPTOP_SPEAKERS)
        echo "Toggling output to Volumio Speakers..."
        pactl move-sink-input $INPUT $VOLUMIO_SPEAKERS
        ;;
    $VOLUMIO_SPEAKERS)
        echo "Toggling output to Laptop Speakers..."
        pactl move-sink-input $INPUT $LAPTOP_SPEAKERS
        ;;
    *)
        echo "Unexpected output sink. Setting to Laptop Speakers..."
        pactl move-sink-input $INPUT $LAPTOP_SPEAKERS
        exit 0
esac
