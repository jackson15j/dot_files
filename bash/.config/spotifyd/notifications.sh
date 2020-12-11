#!/bin/bash
# https://github.com/Spotifyd/spotifyd/wiki/User-supplied-scripts
mkdir -p /tmp/i3/status
if [ "$PLAYER_EVENT" = "start" ] || [ "$PLAYER_EVENT" = "change" ];
then
  trackName=$(playerctl -p spotifyd  metadata title)
  artist=$(playerctl -p spotifyd  metadata artist)
  album=$(playerctl -p spotifyd  metadata album)
  artistAndAlbumName=$(playerctl -p spotifyd  metadata --format "{{ artist }} ({{ album }})")
  track_number=$(playerctl -p spotifyd  metadata | grep trackNumber |awk '{print $3}')
  url=$(playerctl -p spotifyd  metadata | grep url |awk '{print $3}')
  art_url=$(playerctl -p spotifyd  metadata | grep artUrl |awk '{print $3}')
  track_length=$(printf %.2f $(echo "$(playerctl -p spotifyd  metadata | grep length |awk '{print $3}')/60000000"| bc -l))
  wget -O /tmp/art $art_url

  # https://askubuntu.com/questions/189231/where-are-the-stock-icon-names-defined-for-the-unity-panel-service-indicators-an
  notify-send -a spotifyd -i /tmp/art -c applications-multimedia -u low \
              "Track: $track_number $trackName" \
              "Artist: $artist\nAlbum: $album\nLength: $track_length\nUrl: $url"
  echo "$track_number. $trackName - $artistAndAlbumName ($track_length)" > /tmp/i3/status/spotifyd
fi
