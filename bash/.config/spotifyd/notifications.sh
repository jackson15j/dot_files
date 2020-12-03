#!/bin/bash
# https://github.com/Spotifyd/spotifyd/wiki/User-supplied-scripts
mkdir -p /tmp/i3/status
if [ "$PLAYER_EVENT" = "start" ] || [ "$PLAYER_EVENT" = "change" ];
then
  trackName=$(playerctl metadata title)
  artist=$(playerctl metadata artist)
  album=$(playerctl metadata album)
  artistAndAlbumName=$(playerctl metadata --format "{{ artist }} ({{ album }})")
  track_number=$(playerctl metadata | grep trackNumber |awk '{print $3}')
  url=$(playerctl metadata | grep url |awk '{print $3}')
  art_url=$(playerctl metadata | grep artUrl |awk '{print $3}')
  wget -O /tmp/art $art_url

  # https://askubuntu.com/questions/189231/where-are-the-stock-icon-names-defined-for-the-unity-panel-service-indicators-an
  notify-send -a spotifyd -i /tmp/art -c applications-multimedia -u low \
              "Track: $track_number $trackName" \
              "Artist: $artist\nAlbum: $album\nUrl: $url"
  echo "$trackName - $artistAndAlbumName" > /tmp/i3/status/spotifyd
fi
